
SELECT *
FROM "outbound"."ReplacementLocations" AS oREPL
WHERE oREPL.locationcalendar_id IN (
  SELECT DISTINCT locationcalendar_id
  FROM "outbound"."LocationCalendar"
  WHERE replacement_ongoing AND NOT is_replaced
)
