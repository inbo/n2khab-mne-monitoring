\COPY (

SELECT
  VIS.grts_address,
  FAC.type,
  VIS.type_assessed,
  VIS.date_start,
  VIS.visit_done,
  FAC.date_visit_planned,
  INFO.accessibility_inaccessible,
  INFO.accessibility_revisit,
  FAC.notes,
  VIS.notes,
  'https://www.openstreetmap.org/?mlat=' ||
    CAST(COORDS.wgs84_y AS VARCHAR) ||
    '&mlon=' ||
    CAST(COORDS.wgs84_x AS VARCHAR)
    AS quicklink
FROM "inbound"."Visits" AS VIS, "outbound"."FieldActivityCalendar" AS FAC
LEFT JOIN "outbound"."LocationInfos" AS INFO
  ON INFO.grts_address = FAC.grts_address
LEFT JOIN "metadata"."Coordinates" AS COORDS
  ON COORDS.grts_address = FAC.grts_address
WHERE VIS.fieldactivitycalendar_id = FAC.fieldactivitycalendar_id
  AND visit_done
  AND date_visit IS NULL

) TO '/data/mnm_db_backups/20251201_dateless_loceval.csv' With CSV DELIMITER ',' HEADER
;
