SELECT *
FROM "inbound"."Visits" AS VIS
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.grts_address = VIS.grts_address
WHERE VIS.location_id IS NULL
;




SELECT * FROM "metadata"."Locations" WHERE grts_address = 6314694;

SELECT * FROM "outbound"."SampleLocations" WHERE grts_address = 6314694;
UPDATE "outbound"."SampleLocations"
SET location_id = 527
WHERE grts_address = 6314694
;

SELECT * FROM "inbound"."Visits" WHERE grts_address = 6314694;
UPDATE "inbound"."Visits"
SET
  location_id = 527,
  samplelocation_id = 527
WHERE grts_address = 6314694
;

SELECT * FROM "outbound"."FieldworkCalendar" WHERE grts_address = 6314694;
UPDATE "outbound"."FieldworkCalendar"
SET
  samplelocation_id = 527
WHERE grts_address = 6314694
;
