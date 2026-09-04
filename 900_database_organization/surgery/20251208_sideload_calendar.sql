

ALTER TABLE "outbound"."FieldworkCalendar" ADD COLUMN is_sideloaded boolean DEFAULT FALSE;
COMMENT ON COLUMN "outbound"."FieldworkCalendar".is_sideloaded IS E'(technical) this calendar event was sideloaded and not part of the POC';
