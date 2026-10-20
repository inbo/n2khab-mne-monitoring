

BEGIN;

DROP VIEW "inbound"."LocevalFieldwork" CASCADE;
CREATE OR REPLACE VIEW "inbound"."LocevalFieldwork" AS
SELECT
  LOC.*,
  UNIT.sampleunit_id,
  UNIT.grts_join_method,
  UNIT.schemes,
  UNIT.scheme_ps_targetpanels_served AS scheme_ps_targetpanels,
  UNIT.type,
  UNIT.domain_part,
  UNIT.is_forest,
  UNIT.in_mhq_samples,
  UNIT.has_mhq_assessment,
  UNIT.mhq_assessment_date,
  UNIT.previous_notes,
  UNIT.replacement_ongoing,
  UNIT.replacement_reason,
  UNIT.replacement_permanence,
  UNIT.is_replaced,
  UNIT.type_is_absent,
  CAL.fieldcalendar_id,
  CAL.activity_group_id,
  CAL.date_start,
  CAL.date_end,
  CAL.date_interval,
  CAL.date_end - current_date AS days_to_deadline,
  CAL.activity_rank,
  CAL.priority,
  CAL.matching_occasion,
  CAL.date_suggested,
  CAL.wait_any,
  CAL.wait_watersurface,
  CAL.wait_3260,
  CAL.wait_7220,
  CAL.wait_floating,
  CAL.wait_obsolete_types,
  CAL.excluded,
  FALSE AS no_visit_planned,
  CAL.excluded_reason,
  CAL.teammember_assigned,
  CAL.date_visit_planned,
  CASE WHEN ((VISIT.visit_done IS TRUE) OR (CAL.excluded IS TRUE))
      THEN NULL
      ELSE (CASE WHEN (CAL.date_visit_planned IS NULL) THEN CAL.date_end ELSE CAL.date_visit_planned END) - current_date
      END AS days_to_visit,
  CAL.notes AS preparation_notes,
  CAL.done_planning,
  CAL.is_frozen,
  VISIT.visit_id,
  VISIT.teammember_id,
  VISIT.date_visit,
  VISIT.type_assessed,
  VISIT.is_well_developed_type,
  VISIT.gps_type,
  VISIT.gps_accuracy_cm,
  VISIT.notes,
  VISIT.photo,
  VISIT.issues,
  (VISIT.othervisit_id IS NOT NULL) AS show_othervisits,
  ((VISIT.othervisit_id IS NOT NULL) AND ACT.is_samplingpoint_activity)
      AS is_samplingpoint_activity,
  (VISIT.aquatictypesvisit_id IS NOT NULL) AS show_aquatictypevisits,
  VISIT.samplingpoint_selection_done,
  VISIT.crassula_was_here,
  (VISIT.terrestrialtypesvisit_id IS NOT NULL) AS show_terrestrialtypevisits,
  VISIT.replacement_recovery_notes,
  VISIT.visit_done,
  INFO.locationinfo_id,
  INFO.landowner,
  INFO.accessibility_inaccessible,
  INFO.accessibility_revisit,
  INFO.permission_notes,
  INFO.recovery_hints,
  INFO.equipment_recommendations,
  INFO.is_secret_location,
  (UNIT.archive_version_id IS NOT NULL)
    OR (CAL.archive_version_id IS NOT NULL)
    OR (VISIT.archive_version_id IS NOT NULL)
    AS is_archived,
  OPHO.assessment_done AS orthophoto_assessment_done,
  OPHO.notes AS orthophoto_notes,
  CASE WHEN CAL.done_planning
      THEN '[✓] '
      ELSE '[_] '
      END ||
    CASE WHEN
      (CAL.priority IS NULL)
      THEN ' '
      ELSE 'prio ' || CAL.priority::VARCHAR || ' '
      END ||
      '`' || CAL.type || '` ' ||
    CASE WHEN
        (VISIT.aquatictypesvisit_id IS NOT NULL)
      THEN '(aq)'
      ELSE '' END ||
    TO_CHAR(CAL.date_start, 'yyyy-mm-dd')
    AS label,
  CASE WHEN
      (VISIT.visit_done IS TRUE)
    THEN 'done'
    ELSE
      CASE WHEN (VISIT.issues IS TRUE)
      THEN 'issues'
      ELSE
        CASE WHEN
          ((CAL.excluded IS TRUE)
            OR (CAL.is_frozen IS TRUE)
          )
        THEN 'irrelevant'
        ELSE CAL.priority::VARCHAR
        END
      END
    END AS status
FROM (
  SELECT *
  FROM ONLY "inbound"."Visits"
  NATURAL FULL JOIN "inbound"."OtherVisits"
  NATURAL FULL JOIN "inbound"."AquaticTypesVisits"
  NATURAL FULL JOIN "inbound"."TerrestrialTypesVisits"
) AS VISIT
LEFT JOIN "outbound"."FieldCalendars" AS CAL
  ON CAL.visit_id = VISIT.visit_id
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = VISIT.location_id
LEFT JOIN "outbound"."LocationInfos" AS INFO
  ON INFO.location_id = VISIT.location_id
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON VISIT.sampleunit_id = UNIT.sampleunit_id
LEFT JOIN (
  SELECT DISTINCT
    sampleunit_id,
    BOOL_OR(cell_disapproved) AS cell_disapproved,
    BOOL_OR(assessment_done) AS assessment_done,
    STRING_AGG(CASE WHEN notes IS NULL THEN '' ELSE notes END, '; ') AS notes
  FROM "outbound"."LocationAssessments"
  GROUP BY
    sampleunit_id
  ) AS OPHO
  ON VISIT.sampleunit_id = OPHO.sampleunit_id
LEFT JOIN (
  SELECT DISTINCT
    activity_group_id, activity_group,
    BOOL_OR(is_loceval_activity) AS is_loceval_activity,
    BOOL_OR(activity LIKE 'SURF%SAMPLPOINT') AS is_samplingpoint_activity
  FROM "metadata"."GroupedActivities"
  WHERE archive_version_id IS NULL
  GROUP BY activity_group_id, activity_group
) AS ACT ON ACT.activity_group_id = CAL.activity_group_id
WHERE TRUE
  AND VISIT.grts_address = CAL.grts_address
  AND VISIT.type = CAL.type
  AND VISIT.date_start = CAL.date_start
  AND VISIT.activity_group_id = CAL.activity_group_id
  AND (
    VISIT.visit_done OR (
          (NOT CAL.wait_any)
      AND (UNIT.archive_version_id IS NULL)
      AND (CAL.archive_version_id IS NULL)
      AND (VISIT.archive_version_id IS NULL)
      AND (NOT (OPHO.cell_disapproved IS TRUE))
    )
  )
  AND ACT.is_loceval_activity
;


-- https://stackoverflow.com/q/44005446
CREATE OR REPLACE RULE LocevalFieldwork_upd_reset AS
ON UPDATE TO "inbound"."LocevalFieldwork"
DO INSTEAD NOTHING
;

DROP RULE IF EXISTS LocevalFieldwork_upd_sampleunits ON "inbound"."LocevalFieldwork";
CREATE OR REPLACE RULE LocevalFieldwork_upd_sampleunits AS
ON UPDATE TO "inbound"."LocevalFieldwork"
DO ALSO
 UPDATE "outbound"."SampleUnits"
 SET
  is_replaced = NEW.is_replaced,
  replacement_ongoing = NEW.replacement_ongoing,
  replacement_reason = NEW.replacement_reason,
  replacement_permanence = NEW.replacement_permanence,
  type_is_absent = NEW.type_is_absent
 WHERE sampleunit_id = OLD.sampleunit_id
;

DROP RULE IF EXISTS LocevalFieldwork_upd_fac ON "inbound"."LocevalFieldwork";
CREATE OR REPLACE RULE LocevalFieldwork_upd_fac AS
ON UPDATE TO "inbound"."LocevalFieldwork"
DO ALSO
 UPDATE "outbound"."FieldCalendars"
 SET
  excluded = NEW.excluded,
  excluded_reason = NEW.excluded_reason,
  teammember_assigned = NEW.teammember_assigned,
  date_visit_planned = NEW.date_visit_planned,
  notes = NEW.preparation_notes,
  done_planning = NEW.done_planning
 WHERE fieldcalendar_id = OLD.fieldcalendar_id
;


DROP RULE IF EXISTS LocevalFieldwork_upd_visits ON "inbound"."LocevalFieldwork";
CREATE OR REPLACE RULE LocevalFieldwork_upd_visits AS
ON UPDATE TO "inbound"."LocevalFieldwork"
DO ALSO
 UPDATE "inbound"."Visits"
 SET
  teammember_id = NEW.teammember_id,
  date_visit = NEW.date_visit,
  type_assessed = NEW.type_assessed,
  is_well_developed_type = NEW.is_well_developed_type,
  gps_type = NEW.gps_type,
  gps_accuracy_cm = NEW.gps_accuracy_cm,
  notes = NEW.notes,
  photo = NEW.photo,
  issues = NEW.issues,
  visit_done = NEW.visit_done
 WHERE visit_id = OLD.visit_id
;

DROP RULE IF EXISTS FieldWork_upd_TerrestrialTypesVisits ON "inbound"."LocevalFieldwork";
CREATE RULE FieldWork_upd_TerrestrialTypesVisits AS
ON UPDATE TO "inbound"."LocevalFieldwork"
DO ALSO
 UPDATE "inbound"."TerrestrialTypesVisits"
 SET
   replacement_recovery_notes = NEW.replacement_recovery_notes,
   replacement_triggered = NEW.replacement_ongoing
 WHERE visit_id = OLD.visit_id
   AND terrestrialtypesvisit_id IS NOT NULL
;

DROP RULE IF EXISTS FieldWork_upd_AquaticTypesVisits ON "inbound"."LocevalFieldwork";
CREATE RULE FieldWork_upd_AquaticTypesVisits AS
ON UPDATE TO "inbound"."LocevalFieldwork"
DO ALSO
 UPDATE "inbound"."AquaticTypesVisits"
 SET
   samplingpoint_selection_done = NEW.samplingpoint_selection_done,
   crassula_was_here = NEW.crassula_was_here
 WHERE visit_id = OLD.visit_id
   AND aquatictypesvisit_id IS NOT NULL
;


CREATE OR REPLACE RULE LocevalFieldwork_upd_locationinfos AS
ON UPDATE TO "inbound"."LocevalFieldwork"
DO ALSO
 UPDATE "outbound"."LocationInfos"
 SET
  recovery_hints = NEW.recovery_hints,
  equipment_recommendations = NEW.equipment_recommendations,
  is_secret_location = NEW.is_secret_location,
  permission_notes = NEW.permission_notes,
  accessibility_inaccessible = NEW.accessibility_inaccessible,
  accessibility_revisit = NEW.accessibility_revisit
 WHERE locationinfo_id = OLD.locationinfo_id
;



GRANT SELECT ON  "inbound"."LocevalFieldwork"  TO viewer_mnmdb;
GRANT UPDATE ON  "inbound"."LocevalFieldwork"  TO user_loceval;

COMMIT;


-- DROP RULE IF EXISTS FieldWork_upd_OTHERVISITS ON "inbound"."FieldWork";
-- CREATE RULE FieldWork_upd_OTHERVISITS AS
-- ON UPDATE TO "inbound"."LocevalFieldwork"
-- DO ALSO
--  UPDATE "inbound"."OtherVisits"
--  SET
--   project_code = NEW.project_code,
--   recipient_code = NEW.recipient_code
--  WHERE othervisit_id = OLD.othervisit_id
--    AND othervisit_id IS NOT NULL
-- ;
