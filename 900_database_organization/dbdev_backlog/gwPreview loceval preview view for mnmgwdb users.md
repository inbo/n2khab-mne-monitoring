---
aliases:
tags:
started:
finished:
execution:
status: false
priority:
---


```sql
CREATE SCHEMA "transfer";
ALTER SCHEMA "transfer" OWNER TO <owner>;

GRANT USAGE ON SCHEMA "transfer" TO reporter_mnmdb;
GRANT USAGE ON SCHEMA "transfer" TO  viewer_mnmdb;

```

```sql
DROP VIEW IF EXISTS  "transfer"."gwPreview" ;
CREATE VIEW "transfer"."gwPreview" AS
SELECT
  LOC.*,
  CAL.fieldcalendar_id,
  CAL.activity_group_id,
  CAL.date_start,
  CAL.date_end,
  CAL.date_interval,
  CAL.date_end - current_date AS days_to_deadline,
  CAL.date_end - current_date < 240 AS near_future,
  VISIT.visit_id,
  VISIT.teammember_id,
  VISIT.date_visit,
  VISIT.type_assessed,
  VISIT.notes,
  VISIT.issues,
  VISIT.visit_done
FROM (
  SELECT *
  FROM ONLY "inbound"."Visits"
  NATURAL FULL JOIN "inbound"."OtherVisits"
  NATURAL FULL JOIN "inbound"."AquaticTypesVisits"
  NATURAL FULL JOIN "inbound"."TerrestrialTypesVisits"
) AS VISIT
LEFT JOIN "outbound"."FieldCalendars" AS CAL
  ON CAL.fieldcalendar_id = VISIT.fieldcalendar_id
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.location_id = VISIT.location_id
WHERE
  CAL.priority <= 4 AND CAL.priority IS NOT NULL
  AND NOT CAL.excluded
  AND NOT CAL.no_visit_planned
  AND NOT CAL.is_frozen
  AND NOT CAL.wait_any
  AND CAL.activity_group_id IN (
   SELECT DISTINCT activity_group_id
   FROM "metadata"."GroupedActivities"
   WHERE activity_group IN ('LOCEVALTERR', 'LOCEVALAQ')
  )
;


GRANT SELECT ON  "transfer"."gwPreview"  TO  reporter_mnmdb, viewer_mnmdb;

```

