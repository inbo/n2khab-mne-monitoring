
-- add domain part to loceval
ALTER TABLE "outbound"."FieldActivityCalendar" ADD COLUMN domain_part varchar;
COMMENT ON COLUMN "outbound"."FieldActivityCalendar".domain_part IS E'domain partition';


-- there is a problem with grts_address = 871030
-- it disappeared, except from LocationInfos, Coordinates, and Locations
SELECT * FROM "metadata"."Coordinates" WHERE grts_address = 871030;
-- temporarily deleted on "staging"
