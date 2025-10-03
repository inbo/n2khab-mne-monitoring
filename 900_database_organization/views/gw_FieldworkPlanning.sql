-- UPDATE "outbound"."FieldworkPlanning" SET watina_code = 'XXX000' WHERE fieldworkcalendar_id = 3;

DROP VIEW IF EXISTS  "outbound"."FieldworkPlanning" CASCADE;
CREATE VIEW "outbound"."FieldworkPlanning" AS
SELECT
  LOC.*,
  SLOC.scheme_ps_targetpanels,
  SSPSTP.stratum_scheme_ps_targetpanels,
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
  FWCAL.activity_group_id IN (
    SELECT DISTINCT activity_group_id FROM "metadata"."GroupedActivities"
    WHERE is_gw_activity
  ) AS is_gw_activity,
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
  ACT.date_visit,
  ACT.has_installation,
  ACT.photo,
  CASE WHEN ACT.date_visit IS NULL THEN NULL
       ELSE current_date - ACT.date_visit
  END AS count_days_ws,
  LOCEVAL.has_loceval,
  LOCEVAL.loceval_photo,
  LOCEVAL.loceval_notes,
  LOCEVAL.latest_visit
FROM "outbound"."FieldworkCalendar" AS FWCAL
LEFT JOIN "outbound"."SampleLocations" AS SLOC
  ON FWCAL.samplelocation_id = SLOC.samplelocation_id
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = SLOC.location_id
LEFT JOIN "outbound"."LocationInfos" AS INFO
  ON LOC.location_id = INFO.location_id
LEFT JOIN "metadata"."SSPSTaPas" AS SSPSTP
  ON SSPSTP.sspstapa_id = FWCAL.sspstapa_id
LEFT JOIN (
  SELECT
    samplelocation_id,
    latest_visit,
    loceval_photo,
    loceval_notes,
    TRUE AS has_loceval
  FROM (
    SELECT DISTINCT
      samplelocation_id,
      eval_source,
      MAX(eval_date) AS latest_visit,
      eval_date,
      photo AS loceval_photo,
      notes AS loceval_notes
    FROM "outbound"."LocationEvaluations" AS LE
    WHERE eval_source = 'loceval'
    GROUP BY samplelocation_id, eval_source, photo, notes, eval_date
  ) WHERE eval_date = latest_visit 
  ) AS LOCEVAL
    ON SLOC.samplelocation_id = LOCEVAL.samplelocation_id
LEFT JOIN (
  SELECT DISTINCT
    VISIT.samplelocation_id,
    VISIT.date_visit,
    VISIT.photo,
    (WIA.fieldwork_id IS NOT NULL) AS has_installation
  FROM "inbound"."Visits" AS VISIT
  LEFT JOIN "inbound"."WellInstallationActivities" AS WIA
    ON VISIT.visit_id = WIA.visit_id
  WHERE VISIT.visit_done
    AND VISIT.activity_group_id IN (
      SELECT DISTINCT activity_group_id
      FROM "metadata"."GroupedActivities"
      WHERE activity_group LIKE 'GWINST%'
    )
    AND VISIT.archive_version_id IS NULL
) AS ACT
  ON FWCAL.samplelocation_id = ACT.samplelocation_id
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
WHERE TRUE
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

-- DROP RULE IF EXISTS FieldworkPlanning_upd0 ON "outbound"."FieldworkPlanning";
-- CREATE RULE FieldworkPlanning_upd0 AS
-- ON UPDATE TO "outbound"."FieldworkPlanning"
-- DO INSTEAD NOTHING;

DROP RULE IF EXISTS FieldworkPlanning_upd1 ON "outbound"."FieldworkPlanning";
CREATE RULE FieldworkPlanning_upd1 AS
ON UPDATE TO "outbound"."FieldworkPlanning"
DO INSTEAD
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

GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  tom;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  yglinga;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  jens;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  lise;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  wouter;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  floris;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  karen;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  ward;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  monkey;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO  tom;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO  floris;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO  karen;

GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  tester;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO  tester;
