---
aliases:
tags:
  - locevaldb
  - SampleUnits
  - stratum
  - duplicates
started: 2026-07-09
finished:
execution:
  - FM
status: false
---

When introducing aquatic sample units,
they were accidentally stored with their `stratum` information in the `type` columns.

# TODO: Replace strata by types

## Chapter 0: Lookup Table
The #N2kHabStrata table should get a `type` column in addition to the `n2khabtype_id`, which simplifies direct lookup.
There are missing ones, so first make the Union set.

*UPDATE:* the following transient lookup can be used in a `WHERE` environment.

```sql
  SELECT type, COALESCE(stratum, type) AS stratum
  FROM "metadata"."N2kHabTypes" TYP
  LEFT JOIN "metadata"."N2kHabStrata" STRAT
  ON TYP.n2khabtype_id = STRAT.n2khabtype_id
  ;
```

### make sure all strata are present

```sql

INSERT INTO "metadata"."N2kHabStrata" (stratum, n2khabtype_id)
VALUES (
  '3110_5_50',
  (SELECT DISTINCT n2khabtype_id
  FROM "metadata"."N2kHabTypes"
  WHERE type = '3110')
);

```

## Chapter 1: Fix the Data
Assuming each table by itself uses *either* stratum *or* type in the field called `type`,
this was solved by an `UPDATE... FROM`:

```sql

BEGIN;

WITH stratum_lookup AS (
  SELECT type, COALESCE(stratum, type) AS stratum
  FROM "metadata"."N2kHabTypes" TYP
  LEFT JOIN "metadata"."N2kHabStrata" STRAT
  ON TYP.n2khabtype_id = STRAT.n2khabtype_id
)
UPDATE "inbound"."Visits" AS TRGTAB
SET
  type = SRCTAB.type
FROM stratum_lookup AS SRCTAB
WHERE
  (TRGTAB.type = SRCTAB.stratum)
  AND TRGTAB.type NOT IN (
  SELECT DISTINCT type
  FROM "metadata"."N2kHabTypes"
)
;

WITH stratum_lookup AS (
  SELECT type, COALESCE(stratum, type) AS stratum
  FROM "metadata"."N2kHabTypes" TYP
  LEFT JOIN "metadata"."N2kHabStrata" STRAT
  ON TYP.n2khabtype_id = STRAT.n2khabtype_id
)
UPDATE "outbound"."FieldCalendars" AS TRGTAB
SET
  type = SRCTAB.type
FROM stratum_lookup AS SRCTAB
WHERE
  (TRGTAB.type = SRCTAB.stratum)
  AND TRGTAB.type NOT IN (
  SELECT DISTINCT type
  FROM "metadata"."N2kHabTypes"
)
;

WITH stratum_lookup AS (
  SELECT type, COALESCE(stratum, type) AS stratum
  FROM "metadata"."N2kHabTypes" TYP
  LEFT JOIN "metadata"."N2kHabStrata" STRAT
  ON TYP.n2khabtype_id = STRAT.n2khabtype_id
)
UPDATE "outbound"."SampleUnits" AS TRGTAB
SET
  type = SRCTAB.type
FROM stratum_lookup AS SRCTAB
WHERE
  (TRGTAB.type = SRCTAB.stratum)
  AND TRGTAB.type NOT IN (
  SELECT DISTINCT type
  FROM "metadata"."N2kHabTypes"
)
;


WITH stratum_lookup AS (
  SELECT type, COALESCE(stratum, type) AS stratum
  FROM "metadata"."N2kHabTypes" TYP
  LEFT JOIN "metadata"."N2kHabStrata" STRAT
  ON TYP.n2khabtype_id = STRAT.n2khabtype_id
)
UPDATE "outbound"."LocationAssessments" AS TRGTAB
SET
  type = SRCTAB.type
FROM stratum_lookup AS SRCTAB
WHERE
  (TRGTAB.type = SRCTAB.stratum)
  AND TRGTAB.type NOT IN (
  SELECT DISTINCT type
  FROM "metadata"."N2kHabTypes"
)
;

COMMIT;

```

## Chapter 2: Fix the Tools


# initial investigation

```sql
SELECT DISTINCT type FROM "outbound"."SampleUnits" ORDER BY type ASC;

SELECT DISTINCT grts_address, type, COUNT(*) AS n, SUM(m) AS m
FROM (
  SELECT 
    SU.grts_address, 
    CASE WHEN STRATYPE.type IS NULL THEN SU.type ELSE STRATYPE.type END AS type,
    sampleunit_id, 
    m
  FROM "outbound"."SampleUnits" AS SU
  LEFT JOIN (
    SELECT 
      CASE WHEN stratum IS NULL THEN type ELSE stratum END AS stratum, 
      type 
    FROM "metadata"."N2kHabTypes" AS T
    LEFT JOIN "metadata"."N2kHabStrata" AS S
      ON T.n2khabtype_id = S.n2khabtype_id
    WHERE NOT (stratum = type)
  ) AS STRATYPE
    ON SU.type = STRATYPE.stratum
  LEFT JOIN (
    SELECT DISTINCT grts_address, type, COUNT(*) AS m
    FROM "outbound"."FieldCalendars"
    GROUP BY grts_address, type
  ) AS CAL
    ON SU.type = CAL.type AND SU.grts_address = CAL.grts_address
)
GROUP BY grts_address, type
HAVING count(*) > 1
ORDER BY n DESC, m DESC
;


SELECT *
FROM "outbound"."FieldCalendars"
WHERE grts_address = 523701
  AND type LIKE '2190%'
;


SELECT DISTINCT grts_address, COUNT(DISTINCT type) AS n
FROM "outbound"."FieldCalendars"
WHERE type LIKE '2190%' OR type LIKE '3%'
GROUP BY grts_address
ORDER BY n DESC
;

SELECT DISTINCT type
FROM "outbound"."FieldCalendars"
WHERE type LIKE '2190%' OR type LIKE '31%'
;

```

... this should be solved by an `UPDATE... FROM` with #N2kHabStrata
just check for #SampleUnits uniqueness.
```sql
SELECT 
  CASE WHEN stratum IS NULL THEN type ELSE stratum END AS stratum, 
  type 
FROM "metadata"."N2kHabTypes" AS T
LEFT JOIN "metadata"."N2kHabStrata" AS S
  ON T.n2khabtype_id = S.n2khabtype_id
WHERE NOT (stratum = type)
;
```


+ make sure this does not repeat on next REP update
+ #LoJos are affected; there better be back-and-forth translation between #mnmsyncdb and #locevaldb: `SELECT DISTINCT type_subset FROM "outbound"."LocationJournals";`


## fix duplicates after preemptive fix

Flag duplicates in the database
```sql
ALTER TABLE "outbound"."SampleUnits"
ADD COLUMN is_duplicate boolean DEFAULT FALSE;

SELECT DISTINCT
grts_address, type, COUNT(*) AS n
FROM "outbound"."SampleUnits"
GROUP BY grts_address, type
HAVING COUNT(*) > 1
;

WITH duplicate_list AS (
  SELECT DISTINCT
  grts_address, type, TRUE AS is_duplicate
  FROM "outbound"."SampleUnits"
  GROUP BY grts_address, type
  HAVING COUNT(*) > 1
  )
UPDATE "outbound"."SampleUnits" TRGTAB
SET is_duplicate = SRCTAB.is_duplicate
FROM duplicate_list AS SRCTAB
WHERE SRCTAB.grts_address = TRGTAB.grts_address
  AND SRCTAB.type = TRGTAB.type
;

```

```sql
\COPY (
  SELECT *
  FROM "outbound"."SampleUnits" AS UNIT
  LEFT JOIN (
      SELECT DISTINCT sampleunit_id, COUNT(*) AS n_visits
      FROM "inbound"."Visits"
      WHERE visit_done
      GROUP BY sampleunit_id
    ) AS VISIT
    ON UNIT.sampleunit_id = VISIT.sampleunit_id
  WHERE UNIT.is_duplicate
  ORDER BY grts_address, type, n_visits
) TO '~/20260915_duplicate_SampleUnits.csv' With CSV DELIMITER ',' HEADER
;

```

Seems like all the obsolete ones have an `archive_version_id`!

```sql

DELETE
  FROM "outbound"."SampleUnits"
  WHERE is_duplicate
AND archive_version_id IS NOT NULL
;

```

Quick checks:
```sql

SELECT DISTINCT
grts_address, type, COUNT(*) AS n
FROM "outbound"."SampleUnits"
GROUP BY grts_address, type
HAVING COUNT(*) > 1
;

SELECT *
FROM "outbound"."FieldCalendars"
WHERE sampleunit_id IS NULL
;



ALTER TABLE "outbound"."SampleUnits"
DROP COLUMN is_duplicate;

```

## Corollary: Duplicate #LocationAssessments

This happened because some SampleUnits disappered and LocAss were relinked.

```
 grts_address |   type   | sampleunit_id | visit_id | n
--------------+----------+---------------+----------+---
       377138 | 3150     |          6677 |     1897 | 2
      1239346 | 3130_aom |          7131 |     3043 | 2
      1239346 | 3130_na  |          7133 |     1996 | 2
      6033970 | 3140     |          7838 |     2239 | 2
      6033970 | 3140     |          7838 |     2846 | 2
(5 rows)

```


-> solved by deleting some prior LocAss which had no notes.

```sql
\COPY (
 SELECT *
 FROM "outbound"."LocationAssessments"
 WHERE grts_address IN (377138, 1239346, 6033970)
 AND assessment_done AND notes IS NULL
) TO '~/20260915_duplicate_LocationAssessments.csv' With CSV DELIMITER ',' HEADER
;
```



# Appendix

## affected tables

+ #SampleUnits -> `type`
+ #SampleUnitPolygons -> `sampleunit_id`
+ #Replacements -> `type`, `sampleunit_id`
+ #LocationAssessments -> `type`, `sampleunit_id`
+ #FieldCalendars -> `type`, `sampleunit_id`
+ #Visits -> `type`, `sampleunit_id`
+ #LocationJournals -> `type_subset`
+ #ReplacementArchives -> `type`
+ #CellMaps -> `type` (hand-filled)
+ #TargetPoints -> `type` (hand-filled)
+ ( #MHQPolygons )

## affected type-stratum-combinations

```sql
SELECT 
  CASE WHEN stratum IS NULL THEN type ELSE stratum END AS stratum, 
  type 
FROM "metadata"."N2kHabTypes" AS T
LEFT JOIN "metadata"."N2kHabStrata" AS S
  ON T.n2khabtype_id = S.n2khabtype_id
WHERE NOT (stratum = type)
;
```


```
     stratum     |   type   
-----------------+----------
 2190_a_0_1      | 2190_a
 2190_a_1_5      | 2190_a
 3110_0_1        | 3110
 3110_1_5        | 3110
 3130_aom_0_1    | 3130_aom
 3130_aom_1_5    | 3130_aom
 3130_aom_5_50   | 3130_aom
 3130_aom_50_150 | 3130_aom
 3130_na_0_1     | 3130_na
 3130_na_1_5     | 3130_na
 3130_na_5_50    | 3130_na
 3130_na_50_150  | 3130_na
 3140_0_1        | 3140
 3140_1_5        | 3140
 3140_5_50       | 3140
 3140_50_150     | 3140
 3150_0_1        | 3150
 3150_1_5        | 3150
 3150_5_50       | 3150
 3150_50_150     | 3150
 3160_0_1        | 3160
 3160_1_5        | 3160
 3160_5_50       | 3160
 rbbah_0_1       | rbbah
 rbbah_1_5       | rbbah
 rbbah_5_50      | rbbah
 rbbah_50_150    | rbbah
 8310_0_2        | 8310
 8310_2_6        | 8310
 8310_6_40       | 8310    
```
    
    
    
    
    