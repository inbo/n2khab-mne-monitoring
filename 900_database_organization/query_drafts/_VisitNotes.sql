SELECT
    ivis.visit_id,
    iVIS.locationcalendar_id,
    mTEAM.username AS team_assigned,
    iVIS.teammember_id,
    CASE WHEN oCAL.stratum_to_expect IS NULL
      THEN oCAL.stratum
      ELSE oCAL.stratum_to_expect
      END as stratum,
    iVIS.stratum_corrected,
    oCAL.notes AS preparation_notes,
    oCAL.visit_date_planned,
    iVIS.date_visit,
    iVIS.visit_due,
    iVIS.visit_overdue,
    iVIS.activity_sequence,
    mACT.activity_group,
    mACT.activity_name,
    iVIS.notes AS field_notes,
    iVIS.visit_done,
    oCAL.wkb_geometry
FROM "inbound"."Visits" AS iVIS
LEFT JOIN "outbound"."LocationCalendar" AS oCAL
 ON iVIS.locationcalendar_id = oCAL.locationcalendar_id
LEFT JOIN "metadata"."TeamMembers" AS mTEAM
 ON oCAL.teammember_assigned = mTEAM.teammember_id
LEFT JOIN "metadata"."GroupedActivities" AS mACT
 ON mACT.grouped_activity_id = iVIS.grouped_activity_id
;

-- oCAL.ogc_fid,

DROP RULE VisitNotes_upd ON "inbound"."VisitNotes";
CREATE RULE VisitNotes_upd AS
ON UPDATE TO "inbound"."VisitNotes"
DO INSTEAD
 UPDATE "inbound"."Visits"
 SET teammember_id = NEW.teammember_id,
     stratum_corrected = NEW.stratum_corrected,
     date_visit = NEW.date_visit,
     visit_due = NEW.visit_due,
     visit_overdue = NEW.visit_overdue,
     activity_sequence = NEW.activity_sequence,
     notes = NEW.field_notes,
     visit_done = NEW.visit_done
 WHERE locationcalendar_id = OLD.locationcalendar_id
;
