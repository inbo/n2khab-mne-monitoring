
SELECT *
  FROM "outbound"."FieldActivityCalendar" AS FAC
LEFT JOIN "outbound"."SampleLocations" AS SLOC
  ON FAC.samplelocation_id = SLOC.samplelocation_id
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = SLOC.location_id
LEFT JOIN (
  SELECT DISTINCT
    location_id,
    cell_disapproved,
    assessment_done
  FROM "outbound"."LocationAssessments"
  GROUP BY
    location_id,
    cell_disapproved,
    assessment_done
  ) AS LOCASS
  ON SLOC.location_id = LOCASS.location_id
WHERE done_planning
;

DROP VIEW IF EXISTS  "outbound"."FieldworkPlanning" ;
CREATE VIEW "outbound"."FieldworkPlanning" AS
SELECT
  LOC.*,
  FAC.fieldactivitycalendar_id,
  FAC.samplelocation_id,
  FAC.activity_group_id,
  FAC.activity_rank,
  FAC.priority,
  FAC.date_start,
  FAC.date_end,
  FAC.date_interval,
  FAC.date_end - current_date AS days_to_deadline,
  FAC.wait_watersurface,
  FAC.wait_3260,
  FAC.wait_7220,
  (FAC.wait_watersurface OR FAC.wait_3260 OR FAC.wait_7220) AS is_waiting,
  FAC.excluded,
  FAC.excluded_reason,
  FAC.landowner,
  FAC.inaccessible,
  FAC.acceccibility_revisit,
  FAC.teammember_assigned,
  FAC.date_visit_planned,
  FAC.no_visit_planned,
  FAC.notes,
  FAC.done_planning,
  SLOC.grts_join_method,
  SLOC.scheme,
  SLOC.panel_set,
  SLOC.targetpanel,
  SLOC.scheme_ps_targetpanels,
  SLOC.sp_poststratum,
  SLOC.type,
  SLOC.assessment,
  SLOC.assessment_date,
  SLOC.previous_notes,
  SLOC.is_replaced,
  LOCASS.cell_disapproved,
  LOCASS.assessment_done
FROM "outbound"."FieldActivityCalendar" AS FAC
LEFT JOIN "outbound"."SampleLocations" AS SLOC
  ON FAC.samplelocation_id = SLOC.samplelocation_id
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = SLOC.location_id
LEFT JOIN (
  SELECT DISTINCT
    location_id,
    cell_disapproved,
    assessment_done
  FROM "outbound"."LocationAssessments"
  GROUP BY
    location_id,
    cell_disapproved,
    assessment_done
  ) AS LOCASS
  ON SLOC.location_id = LOCASS.location_id
ORDER BY
  FAC.date_end,
  FAC.priority,
  is_waiting,
  FAC.stratum,
  FAC.grts_address,
  FAC.activity_rank,
  FAC.activity_group_id
;


DROP RULE IF EXISTS FieldworkPlanning_upd ON "outbound"."FieldworkPlanning";
CREATE RULE FieldworkPlanning_upd AS
ON UPDATE TO "outbound"."FieldworkPlanning"
DO INSTEAD
 UPDATE "outbound"."FieldActivityCalendar"
 SET
  excluded = NEW.excluded,
  excluded_reason = NEW.excluded_reason,
  landowner = NEW.landowner,
  inaccessible = NEW.inaccessible,
  acceccibility_revisit = NEW.acceccibility_revisit,
  teammember_assigned = NEW.teammember_assigned,
  date_visit_planned = NEW.date_visit_planned,
  no_visit_planned = NEW.no_visit_planned,
  notes = NEW.notes,
  done_planning = NEW.done_planning
 WHERE fieldactivitycalendar_id = OLD.fieldactivitycalendar_id
;



GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO ward;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO karen;
GRANT SELECT ON  "outbound"."FieldworkPlanning"  TO floris;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO ward;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO karen;
GRANT UPDATE ON  "outbound"."FieldworkPlanning"  TO floris;
