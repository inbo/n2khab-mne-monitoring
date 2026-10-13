-- UPDATE "outbound"."FieldworkPlanning" SET watina_code = 'XXX000' WHERE fieldcalendar_id = 3;
--  SELECT DISTINCT loceval_positive, loceval_latest_date, loceval_colleague, count(*) FROM "outbound"."FieldworkPlanning" group by loceval_positive, loceval_latest_date, loceval_colleague;


BEGIN;

DROP VIEW IF EXISTS  "outbound"."FieldworkPlanning" CASCADE;
CREATE OR REPLACE VIEW "outbound"."FieldworkPlanning" AS
SELECT
  LOC.*,
  UNIT.scheme_ps_targetpanels_served AS scheme_ps_targetpanels,
  UNIT.schemes,
  UNIT.stratum,
  UNIT.is_forest,
  UNIT.in_mhq_samples,
  UNIT.has_mhq_assessment,
  UNIT.is_replacement,
  REP.grts_address_rep,
  INFO.locationinfo_id,
  INFO.accessibility_inaccessible,
  INFO.accessibility_revisit,
  INFO.landowner,
  INFO.permission_notes,
  INFO.recovery_hints,
  INFO.equipment_recommendations,
  INFO.is_secret_location,
  INFO.watina_code_1,
  INFO.watina_code_2,
  SOIL.soil_info,
  CAL.fieldcalendar_id,
  CAL.sampleunit_id,
  CAL.date_start,
  CAL.date_end,
  CAL.date_interval,
  CAL.date_end - current_date AS days_to_deadline,
  CAL.activity_group_id,
  ACT.activity_group,
  ACT.is_gw_activity,
  CAL.activity_rank,
  CAL.priority,
  CAL.wait_any AS is_waiting,
  CAL.wait_watersurface,
  CAL.wait_3260,
  CAL.wait_7220,
  CAL.wait_floating,
  CAL.wait_obsolete_types,
  CAL.is_frozen,
  CAL.excluded,
  CAL.excluded_reason,
  CAL.teammember_assigned,
  CAL.date_visit_planned,
  CAL.sampling_route_group,
  CAL.notes,
  CAL.done_planning,
  VISIT.visit_id,
  VISIT.visit_date,
  VISIT.visit_photo,
  VISIT.visit_notes,
  VISIT.visit_issues,
  VISIT.visit_done,
  CASE WHEN VISIT.visit_date IS NULL THEN NULL
      ELSE current_date - VISIT.visit_date
    END AS count_days_ws,
  VISIT.installationvisit_id,
  (VISIT.installationvisit_id IS NOT NULL) AS is_installationvisit,
  VISIT.watina_code_used_1_peilbuis,
  VISIT.watina_code_used_2_piezometer,
  VISIT.free_diver,
  VISIT.reused_existing_well,
  VISIT.reused_with_replacement,
  VISIT.samplingvisit_id,
  (VISIT.samplingvisit_id IS NOT NULL) AS is_samplingvisit,
  VISIT.project_code,
  VISIT.recipient_code,
  VISIT.labo_batch,
  INST.has_installation,
  INST.installation_date,
  INST.installation_issues,
  LOCEVAL.loceval_type_assessed,
  LOCEVAL.loceval_positive,
  LOCEVAL.loceval_latest_date,
  LOCEVAL.loceval_colleague,
  LOCEVAL.loceval_photo,
  LOCEVAL.loceval_notes,
  CASE WHEN (
    CAL.is_frozen
    OR CAL.wait_any
    OR (LOCEVAL.loceval_positive IS NULL OR NOT LOCEVAL.loceval_positive)
    OR CAL.excluded
    OR (((CAL.date_end - current_date ) < -30) AND NOT (CAL.done_planning OR VISIT.visit_done))
    )
    THEN 'noplan'
    ELSE
      'p' || LOWER(CAL.done_planning::VARCHAR) ||
      ' v' || LOWER(VISIT.visit_done::VARCHAR)
    END AS status,
  CASE WHEN CAL.done_planning
      THEN '[✓] '
      ELSE '[ ] '
      END ||
    ACT.activity_group || ' ' ||
    CASE WHEN CAL.priority IS NULL
      THEN '(/) '
      ELSE '(' || priority::VARCHAR || ') '
      END ||
    CASE WHEN ((VISIT.visit_done IS NOT NULL) AND VISIT.visit_done)
    THEN TO_CHAR(VISIT.visit_date, 'yyyy-mm-dd')
    ELSE
      CASE WHEN CAL.date_visit_planned IS NULL
      THEN TO_CHAR(CAL.date_start, 'yyyy-mm-dd')
      ELSE TO_CHAR(CAL.date_visit_planned, 'yyyy-mm-dd')
      END
    END AS label
FROM "outbound"."FieldCalendars" AS CAL
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON UNIT.sampleunit_id = CAL.sampleunit_id
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = UNIT.location_id
LEFT JOIN "outbound"."LocationInfos" AS INFO
  ON LOC.location_id = INFO.location_id
LEFT JOIN (
  SELECT DISTINCT location_id, info AS soil_info
  FROM "metadata"."LocationSoilInfos"
  ) AS SOIL
  ON LOC.location_id = SOIL.location_id
LEFT JOIN (
  SELECT
    VIS.visit_id,
    VIS.date_visit AS visit_date,
    VIS.notes AS visit_notes,
    VIS.photo AS visit_photo,
    VIS.issues AS visit_issues,
    VIS.visit_done,
    IVIS.installationvisit_id,
    IVIS.watina_code_used_1_peilbuis,
    IVIS.watina_code_used_2_piezometer,
    IVIS.free_diver,
    IVIS.reused_existing_well,
    IVIS.reused_with_replacement,
    SVIS.samplingvisit_id,
    SVIS.project_code,
    SVIS.recipient_code,
    SVIS.labo_batch
  FROM "inbound"."Visits" VIS
  LEFT JOIN "inbound"."InstallationVisits" IVIS
    ON VIS.visit_id = IVIS.visit_id
    AND VIS.grts_address = IVIS.grts_address
    AND VIS.stratum = IVIS.stratum
  LEFT JOIN "inbound"."SamplingVisits" SVIS
    ON VIS.visit_id = SVIS.visit_id
    AND VIS.grts_address = SVIS.grts_address
    AND VIS.stratum = SVIS.stratum
  )
  AS VISIT
  ON CAL.visit_id = VISIT.visit_id
LEFT JOIN (
  SELECT DISTINCT activity_group_id, activity_group, is_gw_activity
    FROM "metadata"."GroupedActivities"
    GROUP BY activity_group_id, activity_group, is_gw_activity
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
LEFT JOIN (
  SELECT DISTINCT
    type,
    grts_address_original AS grts_address_rep,
    grts_address_replacement AS grts_address
  FROM "transfer"."ReplacementData"
  GROUP BY type, grts_address_original, grts_address_replacement
) AS REP
  ON ((REP.grts_address = UNIT.grts_address)
  AND (UNIT.stratum = REP.type))
LEFT JOIN (
  SELECT
    location_id,
    (source = 'gwdb') AS has_installation,
    CASE WHEN source = 'removal' THEN NULL ELSE date END AS installation_date,
    issues AS installation_issues
  FROM "outbound"."LocationJournals"
  WHERE TRUE
    AND category = 'inst'
    AND is_latest
) AS INST
  ON (LOC.location_id = INST.location_id)
WHERE is_gw_activity
  AND (UNIT.archive_version_id IS NULL)
  AND (CAL.archive_version_id IS NULL)
ORDER BY
  CAL.date_end,
  CAL.priority,
  is_waiting,
  UNIT.stratum,
  CAL.grts_address,
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
CREATE RULE FieldworkPlanning_upd1 AS
ON UPDATE TO "outbound"."FieldworkPlanning"
DO ALSO
 UPDATE "outbound"."FieldCalendars"
 SET
  excluded = NEW.excluded,
  excluded_reason = NEW.excluded_reason,
  teammember_assigned = NEW.teammember_assigned,
  date_visit_planned = NEW.date_visit_planned,
  notes = NEW.notes,
  sampling_route_group = NEW.sampling_route_group,
  done_planning = NEW.done_planning
 WHERE fieldcalendar_id = OLD.fieldcalendar_id
;

-- DROP RULE IF EXISTS FieldworkPlanning_upd_VISITs ON "outbound"."FieldworkPlanning";
-- CREATE RULE FieldworkPlanning_upd_VISITs AS
-- ON UPDATE TO "outbound"."FieldworkPlanning"
-- DO ALSO
--  UPDATE "inbound"."Visits"
--  SET
--   teammember_assigned = NEW.teammember_assigned,
--   date_visit_planned = NEW.date_visit_planned,
--   preparation_notes = NEW.preparation_notes
--  WHERE visit_id = OLD.visit_id
-- ;

DROP RULE IF EXISTS FieldworkPlanning_upd_SVISITs ON "outbound"."FieldworkPlanning";
CREATE RULE FieldworkPlanning_upd_SVISITs AS
ON UPDATE TO "outbound"."FieldworkPlanning"
DO ALSO
 UPDATE "inbound"."SamplingVisits"
 SET
    labo_batch = NEW.labo_batch
 WHERE (visit_id = OLD.visit_id)
   AND (samplingvisit_id = OLD.samplingvisit_id)
;


DROP RULE IF EXISTS FieldworkPlanning_upd2 ON "outbound"."FieldworkPlanning";
CREATE RULE FieldworkPlanning_upd2 AS
ON UPDATE TO "outbound"."FieldworkPlanning"
DO ALSO
 UPDATE "outbound"."LocationInfos"
 SET
  permission_notes = NEW.permission_notes,
  equipment_recommendations = NEW.equipment_recommendations,
  is_secret_location = NEW.is_secret_location,
  watina_code_1 = NEW.watina_code_1,
  watina_code_2 = NEW.watina_code_2
 WHERE locationinfo_id = OLD.locationinfo_id
;

GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  viewer_mnmdb;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO  planner_gwdb;

COMMIT;

-- GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  tester_mnmdb;
-- GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO  tester_mnmdb;


-- REVOKE UPDATE ON  "outbound"."FieldworkPlanning"  FROM  tester;

