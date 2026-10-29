---
aliases:
tags:
  - LocationAssessments
  - orthophotos
  - duplicates
started: 2026-10-06
finished: 2026-10-06
execution:
  - FM
status: true
priority:
---

A slight correction in the #view #gwTransfer  led to a crash by duplicates in the transfer view.
Duplicates were identified and removed.

```sql
BEGIN;

ALTER TABLE "outbound"."LocationAssessments"
ADD COLUMN "is_duplicate" BOOLEAN;

WITH LOCASS_DUPS AS (
  SELECT DISTINCT sampleunit_id, grts_address, type, count(*)
  FROM "outbound"."LocationAssessments"
  GROUP BY sampleunit_id, grts_address, type
  HAVING count(*) > 1
)
UPDATE "outbound"."LocationAssessments"
SET is_duplicate = TRUE
WHERE sampleunit_id IN (
  SELECT DISTINCT sampleunit_id FROM LOCASS_DUPS
)
;

INSERT INTO "outbound"."LocationAssessments"
(
  sampleunit_id,
  location_id,
  log_user,
  log_update,
  grts_address,
  type,
  cell_disapproved,
  revisit_disapproval,
  disapproval_explanation,
  type_suggested,
  implications_habitatmap,
  feedback_habitatmap,
  notes,
  assessment_done,
  is_duplicate
)
SELECT DISTINCT
  sampleunit_id,
  location_id,
  STRING_AGG(DISTINCT log_user, ', ') AS log_user,
  MAX(log_update) AS log_update,
  grts_address,
  type,
  BOOL_OR(cell_disapproved) AS cell_disapproved,
  MIN(revisit_disapproval) AS revisit_disapproval,
  STRING_AGG(DISTINCT disapproval_explanation, ', ') AS disapproval_explanation,
  STRING_AGG(DISTINCT type_suggested, ', ') AS type_suggested,
  BOOL_OR(implications_habitatmap) AS implications_habitatmap,
  STRING_AGG(DISTINCT feedback_habitatmap, ', ') AS feedback_habitatmap,
  STRING_AGG(DISTINCT notes, ', ') AS notes,
  BOOL_OR(assessment_done) AS assessment_done,
  FALSE AS is_duplicate
FROM "outbound"."LocationAssessments"
WHERE is_duplicate
GROUP BY
  sampleunit_id,
  location_id,
  grts_address,
  type
;


\COPY (
  SELECT *
  FROM "outbound"."LocationAssessments" AS LOCASS
  WHERE is_duplicate
  ORDER BY grts_address, type, sampleunit_id, log_update
)  TO '~/20261006_duplicate_location_assessments.csv' With CSV DELIMITER ',' HEADER;
;


DELETE
FROM "outbound"."LocationAssessments" AS LOCASS
WHERE is_duplicate
;

ALTER TABLE "outbound"."LocationAssessments"
DROP COLUMN "is_duplicate";

COMMIT;

```