
-- this unit was visited by Ward and no appropriate replacement found
-- (discussed on the chat because this is close to water and polygon had changed)
-- noted 59629237 somewhere as replacement, but it isn't

-- it is there as a sample location
SELECT * FROM "outbound"."SampleLocations" WHERE grts_address IN (908981) AND strata = '1330_hpr';

-- but nothing on:
SELECT * FROM "outbound"."FieldworkCalendar" WHERE grts_address IN (908981);
SELECT * FROM "archive"."ReplacementData" WHERE grts_address = 908981;

-- ... which is good as is!
