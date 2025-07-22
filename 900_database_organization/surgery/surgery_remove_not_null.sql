ALTER TABLE
  "outbound"."ReplacementLocations"
ALTER COLUMN
  samplelocation_id
  DROP NOT NULL;


-- ... and later:
ALTER TABLE
  "outbound"."ReplacementLocations"
ALTER COLUMN
  samplelocation_id
  SET NOT NULL;
