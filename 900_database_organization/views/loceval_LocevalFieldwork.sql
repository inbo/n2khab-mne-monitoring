

 CASE WHEN ("excluded" OR "no_visit_planned" OR "is_frozen") THEN 'irrelevant'
 ELSE
 CASE WHEN issues THEN 'issues'
 ELSE
 CASE WHEN visit_done THEN 'done'
 ELSE "priority" END
 END
 END


DROP VIEW "inbound"."LocevalFieldwork" CASCADE;
CREATE OR REPLACE VIEW "inbound"."LocevalFieldwork" AS
SELECT
  LOC.*,
  UNIT.sampleunit_id,
  UNIT.grts_join_method,
  UNIT.schemes,
  UNIT.scheme_ps_targetpanels,
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
  FAC.fieldactivitycalendar_id,
  FAC.activity_group_id,
  FAC.date_start,
  FAC.date_end,
  FAC.date_interval,
  FAC.date_end - current_date AS days_to_deadline,
  FAC.activity_rank,
  FAC.priority,
  FAC.wait_any,
  FAC.wait_watersurface,
  FAC.wait_3260,
  FAC.wait_7220,
  FAC.wait_floating,
  FAC.wait_obsolete_types,
  FAC.excluded,
  FAC.excluded_reason,
  FAC.teammember_assigned,
  FAC.date_visit_planned,
  FAC.date_visit_planned - current_date AS days_to_visit,
  FAC.no_visit_planned,
  FAC.notes AS preparation_notes,
  FAC.done_planning,
  FAC.is_frozen,
  VISIT.visit_id,
  VISIT.teammember_id,
  VISIT.date_visit,
  VISIT.type_assessed,
  VISIT.is_well_developed_type,
  VISIT.replacement_recovery_notes,
  VISIT.gps_type,
  VISIT.gps_accuracy_cm,
  VISIT.notes,
  VISIT.photo,
  VISIT.issues,
  VISIT.visit_done,
  INFO.locationinfo_id,
  INFO.landowner,
  INFO.accessibility_inaccessible,
  INFO.accessibility_revisit,
  INFO.recovery_hints,
  OPHO.assessment_done AS orthophoto_assessment_done,
  OPHO.notes AS orthophoto_notes
FROM "inbound"."Visits" AS VISIT
LEFT JOIN "outbound"."FieldActivityCalendar" AS FAC
  ON FAC.fieldactivitycalendar_id = VISIT.fieldactivitycalendar_id
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = VISIT.location_id
LEFT JOIN "outbound"."LocationInfos" AS INFO
  ON INFO.location_id = VISIT.location_id
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON VISIT.sampleunit_id = UNIT.sampleunit_id
LEFT JOIN (
  SELECT DISTINCT
    sampleunit_id,
    cell_disapproved,
    assessment_done,
    CONCAT(notes || ' ') AS notes
  FROM "outbound"."LocationAssessments"
  GROUP BY
    sampleunit_id,
    cell_disapproved,
    assessment_done,
    notes
  ) AS OPHO
  ON VISIT.sampleunit_id = OPHO.sampleunit_id
WHERE TRUE
  AND VISIT.grts_address = FAC.grts_address
  AND VISIT.type = FAC.type
  AND VISIT.date_start = FAC.date_start
  AND VISIT.activity_group_id = FAC.activity_group_id
  AND FAC.wait_any IS FALSE
  AND (UNIT.archive_version_id IS NULL)
  AND (FAC.archive_version_id IS NULL)
  AND (VISIT.archive_version_id IS NULL)
  AND ((OPHO.cell_disapproved IS NULL) OR (NOT OPHO.cell_disapproved))
  AND (FAC.activity_group_id IN
    (SELECT DISTINCT activity_group_id FROM "metadata"."GroupedActivities"
    WHERE is_loceval_activity)
  )
;


-- https://stackoverflow.com/q/44005446
CREATE OR REPLACE RULE LocevalFieldwork_upd_reset AS
ON UPDATE TO "inbound"."LocevalFieldwork"
DO INSTEAD NOTHING
;

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

CREATE OR REPLACE RULE LocevalFieldwork_upd_fac AS
ON UPDATE TO "inbound"."LocevalFieldwork"
DO ALSO
 UPDATE "outbound"."FieldActivityCalendar"
 SET
  excluded = NEW.excluded,
  excluded_reason = NEW.excluded_reason,
  teammember_assigned = NEW.teammember_assigned,
  date_visit_planned = NEW.date_visit_planned,
  no_visit_planned = NEW.no_visit_planned,
  notes = NEW.preparation_notes,
  done_planning = NEW.done_planning
 WHERE fieldactivitycalendar_id = OLD.fieldactivitycalendar_id
;


CREATE OR REPLACE RULE LocevalFieldwork_upd_visits AS
ON UPDATE TO "inbound"."LocevalFieldwork"
DO ALSO
 UPDATE "inbound"."Visits"
 SET
  teammember_id = NEW.teammember_id,
  date_visit = NEW.date_visit,
  type_assessed = NEW.type_assessed,
  is_well_developed_type = NEW.is_well_developed_type,
  replacement_recovery_notes = NEW.replacement_recovery_notes,
  gps_type = NEW.gps_type,
  gps_accuracy_cm = NEW.gps_accuracy_cm,
  notes = NEW.notes,
  photo = NEW.photo,
  issues = NEW.issues,
  visit_done = NEW.visit_done
 WHERE visit_id = OLD.visit_id
;

CREATE OR REPLACE RULE LocevalFieldwork_upd_locationinfos AS
ON UPDATE TO "inbound"."LocevalFieldwork"
DO ALSO
 UPDATE "outbound"."LocationInfos"
 SET
  recovery_hints = NEW.recovery_hints,
  accessibility_inaccessible = NEW.accessibility_inaccessible,
  accessibility_revisit = NEW.accessibility_revisit
 WHERE locationinfo_id = OLD.locationinfo_id
;



GRANT SELECT ON  "inbound"."LocevalFieldwork"  TO viewer_mnmdb;
GRANT UPDATE ON  "inbound"."LocevalFieldwork"  TO user_loceval;
