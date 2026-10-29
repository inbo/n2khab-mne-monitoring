---
aliases:
tags:
  - mnmgwdb
  - PositioningVisits
  - FieldWork
started:
finished:
execution:
status: false
priority: 1
---


[[timeline/2026-10-14|2026-10-14]] #YDC noticed that some positioning activities did not appear in the QGIS app.

> [!note] Cause:
> The reason was that those #Visits ended up in #OtherVisits instead of the specialized `*Visits` child tables.

For the #PositioningVisits , this was solved temporarily:

```sql
BEGIN;

INSERT INTO
"inbound"."PositioningVisits"
(
log_user,
log_update,
fieldcalendar_id,
sampleunit_id,
location_id,
sspstapa_id,
grts_address,
stratum,
activity_group_id,
date_start,
teammember_id,
date_visit,
notes,
photo,
issues,
visit_done,
archive_version_id
)
SELECT
log_user,
log_update,
fieldcalendar_id,
sampleunit_id,
location_id,
sspstapa_id,
grts_address,
stratum,
activity_group_id,
date_start,
teammember_id,
date_visit,
notes,
photo,
issues,
visit_done,
archive_version_id
FROM "inbound"."OtherVisits"
WHERE activity_group_id = 28
;

DELETE
FROM "inbound"."OtherVisits"
WHERE activity_group_id = 28
;


COMMIT;

```

followed by `Rscript 102_re_link_foreign_keys.R`.


There are more mismatches; to be followed up!