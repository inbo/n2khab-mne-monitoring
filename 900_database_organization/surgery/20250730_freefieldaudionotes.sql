

ALTER TABLE "inbound"."FreeFieldNotes" ADD COLUMN audio varchar;
COMMENT ON COLUMN "inbound"."FreeFieldNotes".audio IS E'audio message to brighten up your rainy days';


-- add to qfield
