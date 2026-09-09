---
aliases:
tags:
  - RandomPoints
  - InstallationPoints
started:
finished:
execution:
status: false
priority:
---


- add column `stratum`

```sql
BEGIN;

-- basic rename
ALTER TABLE "outbound"."RandomPoints" RENAME TO "InstallationPoints";

ALTER TABLE "outbound"."InstallationPoints" RENAME COLUMN randompoint_id TO installationpoint_id;

-- reset serial
SELECT setval(pg_get_serial_sequence('"outbound"."InstallationPoints"', 'installationpoint_id'), COALESCE(MAX(installationpoint_id), 1)) FROM "outbound"."InstallationPoints";


-- new column: stratum
ALTER TABLE "outbound"."InstallationPoints" ADD COLUMN stratum varchar NOT NULL; 
COMMENT ON COLUMN "outbound"."InstallationPoints".stratum IS E'stratum for which the cell is eligible';

UPDATE "outbound"."InstallationPoints" AS TRGTAB
  SET
   stratum = SRCTAB.stratum
  FROM "outbound"."SampleUnits" AS SRCTAB
  WHERE
   (TRGTAB.sampleunit_id = SRCTAB.sampleunit_id) AND (TRGTAB.grts_address = SRCTAB.grts_address)
;

-- redirecting view
DROP VIEW IF EXISTS "outbound"."RandomPoints" ;
CREATE VIEW "outbound"."RandomPoints" AS
SELECT
  *
FROM "outbound"."InstallationPoints"
;

COMMIT;
```


- derived view #RandomPlacement