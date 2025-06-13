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
