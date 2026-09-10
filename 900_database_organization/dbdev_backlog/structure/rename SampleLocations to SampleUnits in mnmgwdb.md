---
aliases:
tags:
  - SampleUnits
  - stratum
  - rename
  - mnmgwdb
started: 2026-09-07
finished: 2026-09-10
execution:
  - FM
status: true
priority:
---


Finally, introducing #SampleUnits for #mnmgwdb.
part 1 of [[structure/consistent table and field names across databases summer 2026|the big renaming todo list summer 2026]]

Rename all tables and fields in [[locations/structure sheets|structure sheets]]
+ SampleLocations --> #SampleUnits
+ `samplelocation_id` --> `sampleunit_id`
+ `strata` --> `stratum`
+ also change dependent column names in other tables

For table rename, remove old structure sheet.
Test for creation of `dev` mirror, but apply via `Rename`:

```sql
BEGIN;

ALTER TABLE "outbound"."SampleLocations" RENAME TO "SampleUnits";
ALTER TABLE "outbound"."SampleUnits" RENAME COLUMN samplelocation_id TO sampleunit_id;
ALTER TABLE "outbound"."SampleUnits" RENAME COLUMN strata TO stratum;
ALTER TABLE "transfer"."ReplacementData"
 RENAME COLUMN samplelocation_id TO sampleunit_id;
ALTER TABLE "outbound"."RandomPoints"
 RENAME COLUMN samplelocation_id TO sampleunit_id;
ALTER TABLE "outbound"."MHQPolygons"
 RENAME COLUMN samplelocation_id TO sampleunit_id;
ALTER TABLE "outbound"."LocationEvaluations"
 RENAME COLUMN samplelocation_id TO sampleunit_id;
ALTER TABLE "outbound"."FieldworkCalendar"
 RENAME COLUMN samplelocation_id TO sampleunit_id;
ALTER TABLE "inbound"."Visits"
 RENAME COLUMN samplelocation_id TO sampleunit_id;

ALTER SEQUENCE "outbound".seq_samplelocation_id RENAME TO seq_sampleunit_id;

-- comment on Visits
COMMENT ON TABLE "inbound"."Visits" IS E'inbound information about location visits, planned in FieldCalendars, linked to SampleUnits and field activity GROUP';

-- comment on SampleUnits archive_version_id
COMMENT ON COLUMN "outbound"."SampleUnits".archive_version_id IS E'archived SampleUnits are retained but flagged';

-- comment on FieldworkCalendar stratum
COMMENT ON COLUMN "outbound"."FieldworkCalendar".stratum IS E'stratum for which the cell is eligible';

-- comment on Visits stratum
COMMENT ON COLUMN "inbound"."Visits".stratum IS E'stratum for which the cell is eligible';

-- reset serial
SELECT setval(pg_get_serial_sequence('"outbound"."SampleUnits"', 'sampleunit_id'), COALESCE(MAX(sampleunit_id), 1)) FROM "outbound"."SampleUnits";

-- create a redirecting view with the old name:
DROP VIEW IF EXISTS  "outbound"."SampleLocations" ;
CREATE VIEW "outbound"."SampleLocations" AS
SELECT
  sampleunit_id AS samplelocation_id,
  location_id,
  grts_address,
  stratum AS strata,
  schemes,
  scheme_ps_targetpanels_served,
  domain_part,
  is_forest,
  in_mhq_samples,
  has_mhq_assessment,
  is_replacement,
  was_replaced_by_grts,
  archive_version_id
FROM "outbound"."SampleUnits"
;

COMMIT;
```

+ [x] How about child tables? e.g. #OtherVisits --> yes, cascaded rename

+ [x] check that the sequence/key/constraint is still active and counting --> no, it was reset in the rename
	+ ```sql
    -- SELECT nextval('outbound.seq_sampleunit_id');
    ``` 


+ [x] check that the simple view redirects `INSERT` and `UPDATE` -> works!
	+ ```sql
	  -- INSERT INTO "outbound"."SampleLocations" (
      --   grts_address, strata, schemes, is_forest,
      --   in_mhq_samples, has_mhq_assessment, is_replacement, archive_version_id
	  -- ) VALUES ( 123456, '3130', 'GW03.3', FALSE, TRUE, FALSE, TRUE, NULL );
	  -- UPDATE "outbound"."SampleLocations" SET is_replacement = FALSE WHERE grts_address = 123456;
      -- UPDATE "outbound"."SampleLocations" SET strata = '0815' WHERE grts_address = 123456;
	  -- SELECT * FROM "outbound"."SampleUnits"; 
	  ```

update names in all views
- gw_LocevalInfo.sql
- gw_MHQSafety.sql
- gw_MissingTeammember.sql
- gw_SampleCells.sql
- gw_FieldWork.sql
- gw_FieldworkPlanning.sql

update names in all maintenance scripts

update QGIS projects