---
aliases:
tags:
  - mnmsurfdb
  - Visits
  - datetime
  - trigger
started: 2026-07-08
finished: 2026-07-08
execution:
  - FM
status: true
---


+ `datetime` works for `SURF*DATACOLL` #Visits activities; however, the date must be derived

```sql
UPDATE "inbound"."Visits"
SET
  date_visit = datetime_visit::date
WHERE date_visit IS NULL AND datetime_visit IS NOT NULL;
```
+ and via trigger:
```sql

DROP FUNCTION IF EXISTS "metadata".visit_date_from_datetime CASCADE;
CREATE OR REPLACE FUNCTION "metadata".visit_date_from_datetime()
RETURNS trigger AS
$visit_date_from_datetime$
BEGIN
  IF (NEW.datetime_visit IS NOT NULL) THEN
    NEW.date_visit := NEW.datetime_visit::date;
  END IF;
  RETURN NEW
  ;
END;
$visit_date_from_datetime$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS visit_datetime_to_date ON "inbound"."Visits";
CREATE TRIGGER visit_datetime_to_date
BEFORE UPDATE ON "inbound"."Visits"
FOR EACH ROW EXECUTE PROCEDURE "metadata".visit_date_from_datetime();

DROP TRIGGER IF EXISTS othervisit_datetime_to_date ON "inbound"."OtherVisits";
CREATE TRIGGER othervisit_datetime_to_date
BEFORE UPDATE ON "inbound"."OtherVisits"
FOR EACH ROW EXECUTE PROCEDURE "metadata".visit_date_from_datetime();

DROP TRIGGER IF EXISTS lenticvisit_datetime_to_date ON "inbound"."LenticVisits";
CREATE TRIGGER lenticvisit_datetime_to_date
BEFORE UPDATE ON "inbound"."LenticVisits"
FOR EACH ROW EXECUTE PROCEDURE "metadata".visit_date_from_datetime();

DROP TRIGGER IF EXISTS loticvisit_datetime_to_date ON "inbound"."LoticVisits";
CREATE TRIGGER loticvisit_datetime_to_date
BEFORE UPDATE ON "inbound"."LoticVisits"
FOR EACH ROW EXECUTE PROCEDURE "metadata".visit_date_from_datetime();

```

> [!important] triggers are not inherited
> During testing, I figured that triggers are not inherited and must be applied to all child tables separately.
> This also applied to loceval Visits logging columns.