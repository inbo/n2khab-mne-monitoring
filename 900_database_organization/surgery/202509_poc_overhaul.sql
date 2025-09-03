
-- add domain part to loceval
ALTER TABLE "outbound"."FieldActivityCalendar" ADD COLUMN domain_part varchar;
COMMENT ON COLUMN "outbound"."FieldActivityCalendar".domain_part IS E'domain partition';


