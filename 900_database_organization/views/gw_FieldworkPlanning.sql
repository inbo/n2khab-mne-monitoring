-- UPDATE "outbound"."FieldworkPlanning" SET watina_code = 'XXX000' WHERE fieldworkcalendar_id = 3;
--

DROP VIEW IF EXISTS  "outbound"."FieldworkPlanning" CASCADE;
CREATE VIEW "outbound"."FieldworkPlanning" AS
SELECT
  LOC.*,
  SLOC.scheme_ps_targetpanels,
  SLOC.schemes,
  SLOC.strata,
  SLOC.is_forest,
  SLOC.in_mhq_samples,
  SLOC.has_mhq_assessment,
  SLOC.is_replacement,
  REP.grts_address_poc,
  INFO.locationinfo_id,
  INFO.accessibility_inaccessible,
  INFO.accessibility_revisit,
  INFO.landowner,
  INFO.recovery_hints,
  INFO.watina_code_1,
  INFO.watina_code_2,
  FWCAL.fieldworkcalendar_id,
  FWCAL.samplelocation_id,
  FWCAL.date_start,
  FWCAL.date_end,
  FWCAL.date_interval,
  FWCAL.date_end - current_date AS days_to_deadline,
  FWCAL.activity_group_id,
  ACT.activity_group,
  ACT.is_gw_activity,
  FWCAL.activity_rank,
  FWCAL.priority,
  FWCAL.wait_watersurface,
  FWCAL.wait_3260,
  FWCAL.wait_7220,
  (FWCAL.wait_watersurface OR FWCAL.wait_3260 OR FWCAL.wait_7220) AS is_waiting,
  FWCAL.excluded,
  FWCAL.excluded_reason,
  FWCAL.teammember_assigned,
  FWCAL.date_visit_planned,
  FWCAL.no_visit_planned,
  FWCAL.notes,
  FWCAL.done_planning,
  VISIT.date_visit,
  VISIT.photo,
  VISIT.visit_done,
  CASE WHEN VISIT.date_visit IS NULL THEN NULL
       ELSE current_date - VISIT.date_visit
  END AS count_days_ws,
  WIA.fieldwork_id IS NOT NULL AS has_installation,
  LOCEVAL.has_loceval,
  LOCEVAL.type_assessed,
  LOCEVAL.type_is_absent,
  LOCEVAL.loceval_photo,
  LOCEVAL.loceval_notes,
  LOCEVAL.latest_visit
FROM "outbound"."FieldworkCalendar" AS FWCAL
LEFT JOIN "outbound"."SampleLocations" AS SLOC
  ON SLOC.samplelocation_id = FWCAL.samplelocation_id
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = SLOC.location_id
LEFT JOIN "outbound"."LocationInfos" AS INFO
  ON LOC.location_id = INFO.location_id
LEFT JOIN "inbound"."Visits" AS VISIT
  ON FWCAL.fieldworkcalendar_id = VISIT.fieldworkcalendar_id
LEFT JOIN "inbound"."WellInstallationActivities" AS WIA
    ON VISIT.visit_id = WIA.visit_id
LEFT JOIN (
  SELECT DISTINCT activity_group_id, activity_group, is_gw_activity
    FROM "metadata"."GroupedActivities"
    GROUP BY activity_group_id, activity_group, is_gw_activity
  ) AS ACT
    ON ACT.activity_group_id = FWCAL.activity_group_id
LEFT JOIN (
  SELECT
    grts_address,
    latest_visit,
    loceval_photo,
    loceval_notes,
    type_assessed,
    type_is_absent,
    TRUE AS has_loceval
  FROM (
    SELECT DISTINCT
      grts_address,
      eval_source,
      MAX(eval_date) AS latest_visit,
      eval_date,
      type_assessed,
      type_is_absent,
      photo AS loceval_photo,
      notes AS loceval_notes
    FROM "outbound"."LocationEvaluations" AS LE
    WHERE eval_source = 'loceval'
    GROUP BY grts_address, eval_source,
      photo, notes, eval_date,
      type_assessed, type_is_absent
  ) WHERE eval_date = latest_visit 
  ) AS LOCEVAL
    ON SLOC.grts_address = LOCEVAL.grts_address
    AND SLOC.strata = LOCEVAL.type_assessed
LEFT JOIN (
  SELECT DISTINCT
    type,
    grts_address AS grts_address_poc,
    grts_address_replacement AS grts_address
  FROM "archive"."ReplacementData"
  GROUP BY type, grts_address, grts_address_replacement
) AS REP
  ON ((REP.grts_address = SLOC.grts_address)
  AND (SLOC.strata = REP.type))
WHERE is_gw_activity
  AND FWCAL.archive_version_id IS NULL
ORDER BY
  FWCAL.date_end,
  FWCAL.priority,
  is_waiting,
  SLOC.strata,
  FWCAL.grts_address,
  FWCAL.activity_rank,
  FWCAL.activity_group_id
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
 UPDATE "outbound"."FieldworkCalendar"
 SET
  excluded = NEW.excluded,
  excluded_reason = NEW.excluded_reason,
  teammember_assigned = NEW.teammember_assigned,
  date_visit_planned = NEW.date_visit_planned,
  no_visit_planned = NEW.no_visit_planned,
  notes = NEW.notes,
  done_planning = NEW.done_planning
 WHERE fieldworkcalendar_id = OLD.fieldworkcalendar_id
;

DROP RULE IF EXISTS FieldworkPlanning_upd2 ON "outbound"."FieldworkPlanning";
CREATE RULE FieldworkPlanning_upd2 AS
ON UPDATE TO "outbound"."FieldworkPlanning"
DO ALSO
 UPDATE "outbound"."LocationInfos"
 SET
  watina_code_1 = NEW.watina_code_1,
  watina_code_2 = NEW.watina_code_2
 WHERE locationinfo_id = OLD.locationinfo_id
;

GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  tom, yglinga, jens, lise, wouter, floris, karen, ward, monkey;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO  tom, floris, karen;

GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  tester;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO  tester;

