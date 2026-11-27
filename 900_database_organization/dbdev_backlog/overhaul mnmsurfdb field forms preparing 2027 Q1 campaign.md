---
aliases:
tags:
  - mnmsurfdb
  - FieldWork
  - Observations
  - qgis
  - qfield
started: 2026-11-26
finished:
execution:
status: false
priority: 10
---


The previously used field #forms #fieldforms for capturing #mnmsurfdb #FieldWork were rather extensive. 
This was by purposeful design, since they served a test phase in which we still had to identify relevant information.

Preparing an intense winter campaign, we overhauled these forms.
#NDT has previously collected feedback from all stakeholders, and suggested changes on [[timeline/2026-11-25|2026-11-25]].

# Implementation Steps
## broader cleanup

Some excess fields had become obsolete shortly after inauguration of this database. 
Those were removed on [[timeline/2026-11-26|2026-11-26]].

## Unused `*Observations` Tables

### background
#Observations were introduced [[timeline/2026-07-02|2026-07-02]].
Shortly after, they were re-organized to match fieldwork concepts and technical requirements.

The obsolete tables contain:
+ `GeoObservations` --> 2 entries of 202607
+ `TerraBioObservations` --> 1 entry
+ `AquaBioObservations` --> 2 entries 2 entries
+ `LanduseObservations` --> 0 entries --> drop directly

These remaining data points stem from [[timeline/2026-07-07|our very first field test]] and are almost not worth transferring to the current logic.

### backup
Main focus here is on creating a meaningful backup for later access, before dropping the origin tables.
Using [[sql_tricks/create table as|`CREATE TABLE ... AS`]]:

```sql
CREATE TABLE "archive"."ObsoleteObservations2026Q4"
AS SELECT *
  FROM "inbound"."GeoObservations" GEO
NATURAL FULL JOIN "inbound"."TerraBioObservations" TERRA
NATURAL FULL JOIN "inbound"."AquaBioObservations" AQUA
NATURAL FULL JOIN "inbound"."LanduseObservations" LAND
;
```

### data migration

Using simple spreadsheet investigation to find which fields actually contain data:
```sql
\COPY (
SELECT * FROM "archive"."ObsoleteObservations2026Q4"
) TO '/data/mnm_db_backups/20261127_obsolete_Observations.csv' With CSV DELIMITER ',' HEADER
;
```

+ `notes` and `photo` could be filled
+  `grts_address` and `is_linked_to_visit` should be corrected

Because these were only two locations,
I hand-edited the field forms in QGIS.

### Drop Tables

```sql
DROP TABLE IF EXISTS "inbound"."GeoObservations";
DROP TABLE IF EXISTS "inbound"."TerraBioObservations";
DROP TABLE IF EXISTS "inbound"."AquaBioObservations";
DROP TABLE IF EXISTS "inbound"."LanduseObservations";
```


## Data Uniformity
There was a mix of using percentages and classes, which might be user-dependent.
e.g. 
```sql
SELECT DISTINCT log_user, shading FROM "inbound"."SampleContextObservations";
```

Those must be homogenized asap.