

DROP VIEW IF EXISTS  "outbound"."FieldActivityCalendar" CASCADE;
CREATE OR REPLACE VIEW "outbound"."FieldActivityCalendar" AS
SELECT fieldcalendar_id AS fieldactivitycalendar_id, *
FROM "outbound"."FieldCalendars"
;
