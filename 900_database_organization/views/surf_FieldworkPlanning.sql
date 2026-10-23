
-- auto-update "excluded" for disapproved LOCEVALs
SELECT
  grts_address,
  type,
  type_assessed,
  type_is_absent,
  CASE WHEN type_is_absent
FROM "transfer"."LocationEvaluations"
WHERE eval_source = "loceval"
;

SELECT *
FROM "outbound"."FieldworkPlanning"
WHERE grts_address = 1012434
;

SELECT *
FROM "metadata"."N2kHabStrata"
;



BEGIN;

DROP VIEW IF EXISTS  "outbound"."FieldworkPlanning" CASCADE;
CREATE OR REPLACE VIEW "outbound"."FieldworkPlanning" AS
SELECT
  LOC.*,
  UNIT.sampleunit_id,
  UNIT.stratum,
  UNIT.scheme_ps_targetpanels_served AS scheme_ps_targetpanels,
  UNIT.schemes,
  UNIT.domain_part,
  UNIT.is_forest,
  UNIT.in_mhq_samples,
  UNIT.has_mhq_assessment,
  INFO.locationinfo_id,
  INFO.accessibility_inaccessible,
  INFO.accessibility_revisit,
  INFO.permission_notes,
  INFO.landowner,
  INFO.recovery_hints,
  INFO.equipment_recommendations,
  INFO.is_secret_location,
  CAL.fieldcalendar_id,
  CAL.activity_group_id,
  ACT.activity_group,
  ACT.activity_group LIKE '%LENT%' AS is_lentic,
  ACT.activity_group LIKE '%LOT%' AS is_lotic,
  ACT.default_protocol_id,
  CAL.activity_rank,
  CAL.date_start,
  CAL.date_end,
  CAL.date_interval,
  CAL.date_end - current_date AS days_to_deadline,
  CAL.priority,
  CAL.matching_occasion,
  CAL.date_suggested,
  CAL.wait_any AS is_waiting,
  CAL.wait_watersurface,
  CAL.wait_3260,
  CAL.wait_7220,
  CAL.wait_floating,
  CAL.wait_obsolete_types,
  CAL.is_sideloaded,
  CAL.is_frozen,
  CAL.excluded,
  CAL.excluded_reason,
  CAL.done_planning,
  CAL.visit_id,
  VISIT.teammember_assigned,
  VISIT.date_visit_planned,
  VISIT.preparation_notes,
  VISIT.date_visit,
  VISIT.photo,
  VISIT.protocol_id,
  VISIT.visit_done,
  LOCEVAL.loceval_type_assessed,
  LOCEVAL.loceval_positive,
  LOCEVAL.loceval_latest_date,
  LOCEVAL.loceval_colleague,
  LOCEVAL.loceval_photo,
  LOCEVAL.loceval_notes,
  CASE WHEN
    (CAL.is_frozen IS TRUE)
    OR (CAL.wait_any IS TRUE)
    OR (CAL.excluded IS TRUE)
    THEN 'noplan'
    ELSE
      CASE WHEN
        (CAL.done_planning IS FALSE)
      THEN 'todo'
      ELSE
        CASE WHEN
          (VISIT.visit_done IS TRUE)
        THEN 'visited'
        ELSE 'done'
        END
      END
    END AS status,
  CASE WHEN CAL.done_planning
      THEN '[✓] '
      ELSE '[_] '
      END ||
    SUBSTRING(ACT.activity_group from 4 for 5)  || ' ' ||
    CASE WHEN
      (CAL.priority IS NULL)
      THEN '(/) '
      ELSE '(' || CAL.priority::VARCHAR || ') '
      END ||
    TO_CHAR(CAL.date_start, 'yyyy-mm-dd') || ', ' ||
    CAL.stratum || ')'
  AS label
FROM "outbound"."FieldCalendars" AS CAL
LEFT JOIN "inbound"."Visits" AS VISIT
  ON CAL.visit_id = VISIT.visit_id
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON UNIT.sampleunit_id = CAL.sampleunit_id
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = UNIT.location_id
LEFT JOIN "outbound"."LocationInfos" AS INFO
  ON LOC.location_id = INFO.location_id
LEFT JOIN (
 SELECT
    activity_group_id,
    activity_group,
    is_surf_activity,
    protocol_id AS default_protocol_id
   FROM "metadata"."ActivityGroups"
   WHERE archive_version_id IS NULL
     AND is_surf_activity
 ) AS ACT
   ON ACT.activity_group_id = CAL.activity_group_id
LEFT JOIN (
  SELECT
    LJ.loceval_latest_date,
    LJ.grts_address,
    LE.type,
    LE.loceval_type_assessed,
    STRAT.stratum,
    LJ.loceval_replacement,
    LE.loceval_positive,
    LE.loceval_colleague,
    LE.loceval_photo,
    LE.loceval_notes
  FROM (
    SELECT DISTINCT
      location_id,
      grts_address,
      UNNEST(ARRAY(SELECT TRIM(UNNEST(STRING_TO_ARRAY(type_subset, ','))))) AS type,
      date AS loceval_latest_date,
      loceval_replacement,
      loceval_type_absence
    FROM "outbound"."LocationJournals"
    WHERE TRUE
      AND category IN ('biot', 'loceval')
      AND is_latest
  ) AS LJ
  LEFT JOIN (
    SELECT
      grts_address,
      type,
      type_assessed AS loceval_type_assessed,
      eval_date,
      eval_name AS loceval_colleague,
      (  ((LEVA.type_assessed IS NULL)
         OR (LEVA.type_assessed = LEVA.type))
         AND NOT LEVA.type_is_absent
      ) AS loceval_positive,
      photo AS loceval_photo,
      notes AS loceval_notes
    FROM "transfer"."LocationEvaluations" AS LEVA
    WHERE eval_source = 'loceval'
  ) AS LE
    ON (LE.grts_address = LJ.grts_address)
    AND (LE.type = LJ.type)
    -- AND (LJ.loceval_latest_date = LE.eval_date)
  LEFT JOIN (
    SELECT DISTINCT type, stratum
    FROM "metadata"."N2kHabStrata"
    GROUP BY type, stratum
  ) AS STRAT
  ON LE.type = STRAT.type -- note that this duplicates rows
  WHERE TRUE
    AND LE.grts_address IS NOT NULL
) AS LOCEVAL
  ON UNIT.grts_address = LOCEVAL.grts_address
  AND UNIT.stratum = LOCEVAL.stratum
WHERE TRUE
  AND (ACT.activity_group IS NOT NULL)
  AND (UNIT.archive_version_id IS NULL)
  AND (CAL.archive_version_id IS NULL)
ORDER BY
  CAL.date_end,
  CAL.priority,
  is_waiting,
  UNIT.stratum,
  UNIT.grts_address,
  CAL.activity_rank,
  CAL.activity_group_id
;

-- SELECT DISTINCT visit_done, count(*) FROM "inbound"."Visits" GROUP BY visit_done;
--  AND LOC.grts_address = 48578229

DROP RULE IF EXISTS FieldworkPlanning_upd0 ON "outbound"."FieldworkPlanning";
CREATE RULE FieldworkPlanning_upd0 AS
ON UPDATE TO "outbound"."FieldworkPlanning"
DO INSTEAD NOTHING;

DROP RULE IF EXISTS FieldworkPlanning_upd1 ON "outbound"."FieldworkPlanning";
DROP RULE IF EXISTS FieldworkPlanning_upd_CAL ON "outbound"."FieldworkPlanning";
CREATE RULE FieldworkPlanning_upd_CAL AS
ON UPDATE TO "outbound"."FieldworkPlanning"
DO ALSO
 UPDATE "outbound"."FieldCalendars"
 SET
  excluded = NEW.excluded,
  excluded_reason = NEW.excluded_reason,
  done_planning = NEW.done_planning
 WHERE fieldcalendar_id = OLD.fieldcalendar_id
;

DROP RULE IF EXISTS FieldworkPlanning_upd_VISITs ON "outbound"."FieldworkPlanning";
CREATE RULE FieldworkPlanning_upd_VISITs AS
ON UPDATE TO "outbound"."FieldworkPlanning"
DO ALSO
 UPDATE "inbound"."Visits"
 SET
  teammember_assigned = NEW.teammember_assigned,
  date_visit_planned = NEW.date_visit_planned,
  preparation_notes = NEW.preparation_notes
 WHERE visit_id = OLD.visit_id
;


DROP RULE IF EXISTS FieldworkPlanning_upd2 ON "outbound"."FieldworkPlanning";
DROP RULE IF EXISTS FieldworkPlanning_upd_INFOs ON "outbound"."FieldworkPlanning";
CREATE RULE FieldworkPlanning_upd_INFOs AS
ON UPDATE TO "outbound"."FieldworkPlanning"
DO ALSO
 UPDATE "outbound"."LocationInfos"
 SET
  permission_notes = NEW.permission_notes,
  equipment_recommendations = NEW.equipment_recommendations,
  is_secret_location = NEW.is_secret_location
 WHERE locationinfo_id = OLD.locationinfo_id
;

GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  viewer_mnmdb;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO  planner_surfdb;

COMMIT;

-- GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  tester_mnmdb;
-- GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO  tester_mnmdb;


-- REVOKE UPDATE ON  "outbound"."FieldworkPlanning"  FROM  tester;

