

-- loceval, fwcal
UPDATE "outbound"."FieldActivityCalendar"
SET archive_version_id = NULL
WHERE fieldactivitycalendar_id IN (
  SELECT DISTINCT fieldactivitycalendar_id
  FROM "inbound"."Visits"
  WHERE visit_done
);

-- loceval, visits
UPDATE "inbound"."Visits"
SET archive_version_id = NULL
WHERE fieldactivitycalendar_id IN (
  SELECT DISTINCT fieldactivitycalendar_id
  FROM "inbound"."Visits"
  WHERE visit_done
);


-- mnmgwdb, fwcal
UPDATE "outbound"."FieldworkCalendar"
SET archive_version_id = NULL
WHERE fieldworkcalendar_id IN (
  SELECT DISTINCT fieldworkcalendar_id
  FROM "inbound"."Visits"
  WHERE visit_done
);

-- mnmgwdb, visits
UPDATE "inbound"."Visits"
SET archive_version_id = NULL
WHERE fieldworkcalendar_id IN (
  SELECT DISTINCT fieldworkcalendar_id
  FROM "inbound"."Visits"
  WHERE visit_done
);
