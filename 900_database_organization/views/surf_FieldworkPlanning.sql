-- UPDATE "outbound"."FieldworkPlanning" SET watina_code = 'XXX000' WHERE fieldworkcalendar_id = 3;
--

DROP VIEW IF EXISTS  "outbound"."FieldworkPlanning" CASCADE;
CREATE OR REPLACE VIEW "outbound"."FieldworkPlanning" AS
SELECT
  LOC.*,
  UNIT.stratum,
  UNIT.scheme_ps_targetpanels,
  UNIT.schemes,
  UNIT.domain_part,
  UNIT.is_forest,
  UNIT.in_mhq_samples,
  UNIT.has_mhq_assessment,
  UNIT.is_replacement,
  UNIT.was_replaced_by_grts,
  INFO.locationinfo_id,
  INFO.accessibility_inaccessible,
  INFO.accessibility_revisit,
  INFO.landowner,
  INFO.recovery_hints,
  FCAL.fieldcalendar_id,
  FCAL.sampleunit_id,
  FCAL.activity_group_id,
  FAG.activity_group,
  FCAL.activity_rank,
  FCAL.date_start,
  FCAL.date_end,
  FCAL.date_interval,
  FCAL.date_end - current_date AS days_to_deadline,
  FCAL.priority,
  FCAL.wait_any AS is_waiting,
  FCAL.wait_watersurface,
  FCAL.wait_3260,
  FCAL.wait_7220,
  FCAL.wait_floating,
  FCAL.wait_obsolete_types,
  FCAL.is_frozen,
  FCAL.excluded,
  FCAL.excluded_reason,
  FCAL.teammember_assigned,
  FCAL.date_visit_planned,
  FCAL.no_visit_planned,
  FCAL.notes,
  FCAL.done_planning,
  VISIT.date_visit,
  VISIT.photo,
  VISIT.visit_done,
  CASE WHEN VISIT.date_visit IS NULL THEN NULL
      ELSE current_date - VISIT.date_visit
    END AS count_days_ws,
  INST.has_installation,
  INST.installation_date,
  INST.installation_issues,
  LOCEVAL.loceval_positive,
  LOCEVAL.loceval_latest_date,
  LOCEVAL.loceval_colleague,
  LOCEVAL.loceval_photo,
  LOCEVAL.loceval_notes
FROM "outbound"."FieldCalendar" AS FCAL
LEFT JOIN "inbound"."Visits" AS VISIT
  ON FCAL.fieldcalendar_id = VISIT.fieldcalendar_id
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON UNIT.sampleunit_id = FCAL.sampleunit_id
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = UNIT.location_id
LEFT JOIN "outbound"."LocationInfos" AS INFO
  ON LOC.location_id = INFO.location_id
LEFT JOIN (
  SELECT DISTINCT activity_group_id, activity_group, is_surf_activity
    FROM "metadata"."GroupedActivities"
    GROUP BY activity_group_id, activity_group, is_surf_activity
  ) AS FAG
    ON FAG.activity_group_id = FCAL.activity_group_id
LEFT JOIN (
  SELECT
    LJ.loceval_latest_date,
    LJ.grts_address,
    LE.type AS stratum,
    LJ.loceval_replacement,
    LE.loceval_positive,
    LE.loceval_colleague,
    LE.loceval_photo,
    LE.loceval_notes
  FROM (
    SELECT
      location_id,
      grts_address,
      STRING_TO_ARRAY(type_subset, ',') AS types,
      date AS loceval_latest_date,
      loceval_replacement,
      loceval_type_absence
    FROM "outbound"."LocationJournals"
    WHERE TRUE
      AND category = 'biot'
      AND is_latest
  ) AS LJ
  LEFT JOIN (
    SELECT
      grts_address,
      type,
      eval_date,
      eval_name AS loceval_colleague,
      (  ((type_assessed IS NULL)
         OR (type_assessed = type))
         AND NOT type_is_absent
      ) AS loceval_positive,
      photo AS loceval_photo,
      notes AS loceval_notes
    FROM "transfer"."LocationEvaluations"
    WHERE eval_source = 'loceval'
  ) AS LE
    ON (LE.grts_address = LJ.grts_address)
    AND (CAST(LE.type AS TEXT) = ANY(LJ.types))
    AND (LJ.loceval_latest_date = LE.eval_date)
  WHERE TRUE
    AND (loceval_replacement OR NOT loceval_type_absence)
    AND LE.grts_address IS NOT NULL
) AS LOCEVAL
  ON UNIT.grts_address = LOCEVAL.grts_address
  AND UNIT.stratum = LOCEVAL.stratum
LEFT JOIN (
  SELECT
    location_id,
    (source IN ('surf', 'gwdb')) AS has_installation,
    CASE WHEN source = 'removal' THEN NULL ELSE date END AS installation_date,
    issues AS installation_issues
  FROM "outbound"."LocationJournals"
  WHERE TRUE
    AND category = 'inst'
    AND is_latest
) AS INST
  ON (LOC.location_id = INST.location_id)
WHERE is_surf_activity
  AND (UNIT.archive_version_id IS NULL)
  AND (FCAL.archive_version_id IS NULL)
ORDER BY
  FCAL.date_end,
  FCAL.priority,
  is_waiting,
  UNIT.stratum,
  FCAL.grts_address,
  FCAL.activity_rank,
  FCAL.activity_group_id
;

-- SELECT DISTINCT visit_done, count(*) FROM "inbound"."Visits" GROUP BY visit_done;
--  AND LOC.grts_address = 48578229

DROP RULE IF EXISTS FieldworkPlanning_upd0 ON "outbound"."FieldworkPlanning";
CREATE RULE FieldworkPlanning_upd0 AS
ON UPDATE TO "outbound"."FieldworkPlanning"
DO INSTEAD NOTHING;

DROP RULE IF EXISTS FieldworkPlanning_upd1 ON "outbound"."FieldworkPlanning";
CREATE RULE FieldworkPlanning_upd_CAL AS
ON UPDATE TO "outbound"."FieldworkPlanning"
DO ALSO
 UPDATE "outbound"."FieldCalendar"
 SET
  excluded = NEW.excluded,
  excluded_reason = NEW.excluded_reason,
  teammember_assigned = NEW.teammember_assigned,
  date_visit_planned = NEW.date_visit_planned,
  no_visit_planned = NEW.no_visit_planned,
  notes = NEW.notes,
  done_planning = NEW.done_planning
 WHERE fieldcalendar_id = OLD.fieldcalendar_id
;

GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  viewer_mnmdb;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO  planner_surfdb;

-- GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  tester_mnmdb;
-- GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO  tester_mnmdb;


-- REVOKE UPDATE ON  "outbound"."FieldworkPlanning"  FROM  tester;

