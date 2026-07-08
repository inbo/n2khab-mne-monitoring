---
aliases:
  - trigger
  - sync_mod
tags:
  - triggers
  - sql
  - functions
  - sync_mod
---

Triggers can be used to perform actions whenever a certain event is executed on the database.
For example, the following will call a function (`visit_date_from_datetime`) on each changing row whenever the `Visits` table is updated.

```sql
DROP TRIGGER IF EXISTS visit_datetime_to_date ON "inbound"."Visits";
CREATE TRIGGER visit_datetime_to_date
BEFORE UPDATE ON "inbound"."Visits"
FOR EACH ROW EXECUTE PROCEDURE "metadata".visit_date_from_datetime();
```


The function looks as follows:

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
```


Note that #inheritance does not involve triggers; all child tables must receive their own.

```sql
DROP TRIGGER IF EXISTS othervisit_datetime_to_date ON "inbound"."OtherVisits";
CREATE TRIGGER othervisit_datetime_to_date
BEFORE UPDATE ON "inbound"."OtherVisits"
FOR EACH ROW EXECUTE PROCEDURE "metadata".visit_date_from_datetime();

-- [...] same for other *Visits
```


Functions can be rather complex; here a more involved standard example ( #sync_mod ):

```sql
DROP FUNCTION IF EXISTS "metadata".sync_mod CASCADE;
CREATE OR REPLACE FUNCTION "metadata".sync_mod()
RETURNS trigger AS
$sync_mod$
DECLARE is_teammember BOOLEAN;
BEGIN

  SELECT current_user IN (
    SELECT DISTINCT LOWER(username) FROM "metadata"."TeamMembers"
    WHERE username NOT LIKE 'all_%'
  )
  INTO is_teammember
  ;

  IF is_teammember THEN
    NEW.log_update := current_timestamp(3);
    NEW.log_user := current_user;
  END IF;

  RETURN NEW
  ;
END;
$sync_mod$
LANGUAGE plpgsql;

```
