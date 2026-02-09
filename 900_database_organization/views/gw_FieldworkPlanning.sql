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
  SOIL.soil_info,
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
  INST.has_installation,
  INST.installation_date,
  INST.installation_issues,
  LOCEVAL.loceval_positive,
  LOCEVAL.loceval_latest_date,
  -- LOCEVAL.loceval_replacement,
  LOCEVAL.loceval_colleague,
  LOCEVAL.loceval_photo,
  LOCEVAL.loceval_notes
FROM "outbound"."FieldworkCalendar" AS FWCAL
LEFT JOIN "outbound"."SampleLocations" AS SLOC
  ON SLOC.samplelocation_id = FWCAL.samplelocation_id
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = SLOC.location_id
LEFT JOIN "outbound"."LocationInfos" AS INFO
  ON LOC.location_id = INFO.location_id
LEFT JOIN ( -- soil infos
  SELECT DISTINCT location_id, info AS soil_info
  FROM "metadata"."LocationSoilInfos"
  ) AS SOIL
  ON LOC.location_id = SOIL.location_id
LEFT JOIN "inbound"."Visits" AS VISIT
  ON FWCAL.fieldworkcalendar_id = VISIT.fieldworkcalendar_id
LEFT JOIN "inbound"."WellInstallationActivities" AS WIA
    ON VISIT.visit_id = WIA.visit_id
LEFT JOIN ( -- grouped activities
  SELECT DISTINCT activity_group_id, activity_group, is_gw_activity
    FROM "metadata"."GroupedActivities"
    GROUP BY activity_group_id, activity_group, is_gw_activity
  ) AS ACT
    ON ACT.activity_group_id = FWCAL.activity_group_id
LEFT JOIN ( -- loceval
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
    FROM "outbound"."LocationEvaluations"
    WHERE eval_source = 'loceval'
  ) AS LE
    ON (LE.grts_address = LJ.grts_address)
    AND (CAST(LE.type AS TEXT) = ANY(LJ.types))
    AND (LJ.loceval_latest_date = LE.eval_date)
  WHERE TRUE
    AND (loceval_replacement OR NOT loceval_type_absence)
    AND LE.grts_address IS NOT NULL
) AS LOCEVAL
  ON SLOC.grts_address = LOCEVAL.grts_address
  AND SLOC.strata = LOCEVAL.stratum
LEFT JOIN ( -- replacements
  SELECT DISTINCT
    type,
    grts_address AS grts_address_poc,
    grts_address_replacement AS grts_address
  FROM "archive"."ReplacementData"
  GROUP BY type, grts_address, grts_address_replacement
) AS REP
  ON ((REP.grts_address = SLOC.grts_address)
  AND (SLOC.strata = REP.type))
LEFT JOIN ( -- journal/installations
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

GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  tom, yglinga, jens, lise, wouter, floris, karen, janne, ward, falk, monkey;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO  tom, floris, karen, falk;

GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO  tester;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO  tester;


-- REVOKE UPDATE ON  "outbound"."FieldworkPlanning"  FROM  tester;

