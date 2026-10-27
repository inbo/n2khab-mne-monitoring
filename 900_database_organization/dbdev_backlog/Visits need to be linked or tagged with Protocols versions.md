---
aliases:
  - time- and context-dependent links to Protocols
tags:
  - Protocols
  - Visits
started:
finished:
execution:
status: false
---

By now, #Protocols are associated with #Visits via #GroupedActivities.
This is a useful basic link; however, protocols will change over time and we must record the protocol version at the time of execution.

Rough concept OBSOLETE:
+ introduce a `ProtocolVersions` (PV's) table which links to protocols, captures version changes with date, and might even store a changelog.
+ Then, `Visits` should directly link to PV's; choose sensible/dynamic defaults to facilitate entry for users (with the option to overwrite).

## implementation

+ extra columns to organize #Protocols and fill them
+ add new protocol (standard instrument protocol - `sip`)
+ add `protocol_id` link to #Visits
+ comment on #ActivityGroups `protocol_id`


```sql
BEGIN;

ALTER TABLE "metadata"."Protocols" ADD COLUMN protocol_label varchar UNIQUE; 
COMMENT ON COLUMN "metadata"."Protocols".protocol_label IS E'a unique label for protocol selection';

ALTER TABLE "metadata"."Protocols" ADD COLUMN mnm_scheme varchar; 
COMMENT ON COLUMN "metadata"."Protocols".mnm_scheme IS E'filter MNM-scheme-related protocols';

ALTER TABLE "metadata"."Protocols" ADD COLUMN is_published boolean NOT NULL DEFAULT FALSE; 
COMMENT ON COLUMN "metadata"."Protocols".is_published IS E'flag pre-release additions';

UPDATE "metadata"."Protocols"
SET protocol_label = protocol_code || ' ' || protocol_version
;
ALTER TABLE "metadata"."Protocols" ALTER COLUMN protocol_label SET NOT NULL; 

UPDATE "metadata"."Protocols"
SET
  mnm_scheme = 'loceval'
WHERE protocol_version IN ('2025.-2')
;
UPDATE "metadata"."Protocols"
SET
  mnm_scheme = 'gw'
WHERE protocol_version IN ('2025.-1')
;
UPDATE "metadata"."Protocols"
SET
  mnm_scheme = 'ow'
WHERE protocol_version IN ('2024.05', '2024.06')
;
UPDATE "metadata"."Protocols"
SET
  mnm_scheme = 'mnm'
WHERE protocol_version IN ('2026.-3')
;


INSERT INTO "metadata"."Protocols" (protocol_code, protocol_version, protocol_label, title, subtitle, language, theme, mnm_scheme, is_published)
VALUES ('sip_003_nl', '2026.-3', 'sip_003_nl 2026.-3', 'Landmeting Trimble', NULL, 'nl', 'mnm', 'mnm', FALSE)
;


ALTER TABLE "inbound"."Visits" ADD COLUMN protocol_id int; 
COMMENT ON COLUMN "inbound"."Visits".protocol_id IS E'link to the protocol which was specifically used for this activity';

COMMENT ON COLUMN "metadata"."ActivityGroups".protocol_id IS E'the default protocol currently used for this activity group';

COMMIT;
```

+ update #views
  + [x] #LocevalFieldwork
  + [x] #FieldworkPlanning 
  + [x] #FieldWork

+ modify QGIS projects and distribute

+ Bonus: #ExtraLocevals 
```sql
ALTER TABLE "inbound"."ExtraLocevals" ADD COLUMN protocol_id int;
COMMENT ON COLUMN "inbound"."ExtraLocevals".protocol_id IS E'link to the protocol which was specifically used for this activity';

```