SELECT DISTINCT
    iVIS.visit_id,
    oCAL.wkb_geometry,
    oCAL.locationcalendar_id,
    mTEAM.username AS teammember,
    CASE WHEN iVIS.stratum_corrected IS NULL
     THEN (
       CASE WHEN oCAL.stratum_to_expect IS NULL
        THEN oCAL.stratum
        ELSE oCAL.stratum_to_expect
        END)
     ELSE iVIS.stratum_corrected
     END as stratum,
    iVIS.date_visit,
    mACT.activity_name,
    iVIS.notes AS field_notes
FROM "inbound"."Visits" AS iVIS
LEFT JOIN "outbound"."LocationCalendar" AS oCAL
 ON iVIS.locationcalendar_id = oCAL.locationcalendar_id
LEFT JOIN "metadata"."TeamMembers" AS mTEAM
 ON iVIS.teammember_id = mTEAM.teammember_id
LEFT JOIN "metadata"."GroupedActivities" AS mACT
 ON mACT.grouped_activity_id = iVIS.grouped_activity_id
WHERE
 iVIS.visit_done
;
