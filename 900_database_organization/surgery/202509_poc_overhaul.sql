
-- add domain part to loceval
ALTER TABLE "outbound"."FieldActivityCalendar"
ADD COLUMN domain_part varchar DEFAULT NULL;
