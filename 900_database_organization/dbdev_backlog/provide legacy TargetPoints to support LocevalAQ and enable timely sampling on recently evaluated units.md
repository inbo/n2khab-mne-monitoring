---
aliases:
tags:
  - TargetPoints
  - legacy
started: 2026-07-15
finished:
execution:
status: false
---


+ [x] filter out "SAMPLPOINT" activities -> extra layer


```sql
ALTER TABLE "transfer"."TargetPoints" ADD COLUMN is_legacypoint boolean NOT NULL DEFAULT FALSE; 
COMMENT ON COLUMN "transfer"."TargetPoints".is_legacypoint IS E'flag target points imported from legacy list';

ALTER TABLE "transfer"."TargetPoints" ADD COLUMN try_first boolean NOT NULL DEFAULT FALSE; 
COMMENT ON COLUMN "transfer"."TargetPoints".try_first IS E'prioritize some of the legacy points';

```



Later:

+ [ ] remove `type`
```sql
ALTER TABLE "inbound"."TargetPoints" REMOVE|DROP COLUMN type;
```

+ [ ] link SamplingPoints to Visits (by unit polygon and time) 
+ [ ] yesterday's SamplingPoints are tomorrow's TargetPoints
+ [ ] count previous uses of a TargetPoint (potentially bundling them in 1m clusters?)