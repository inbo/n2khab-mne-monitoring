---
aliases:
  - sync_mod only triggers for actual users
tags:
  - logging
  - sync_mod
  - triggers
started: 2026-05-18
finished: 2026-05-18
execution:
  - FM
status: true
---

There is a `sync_mod` function which captures logging information (i.e. which user changed a db entry at what time).
This function should be conditional on `current_user` to avoid that technical table operations trigger it.
Rather urgent requirement since #mnmsyncdb [[structure/draft and implement mnmsyncdb a database for synchronization of interchange data|implementation]].

```sql
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
    NEW.log_update := current_timestamp;
    NEW.log_user := current_user;
  END IF;

  RETURN NEW
  ;
END;
$sync_mod$
LANGUAGE plpgsql;

```

This will affect (currently): #FreeFieldNotes, #LocationInfos, #FieldCalendar, #Visits, and more.

The old, simpler version was:

```sql
CREATE FUNCTION "metadata".sync_mod() RETURNS trigger AS $sync_mod$
BEGIN
  NEW.log_update := current_timestamp;
  NEW.log_user := current_user;

  RETURN NEW
  ;
END;
```

Implementation trick:
I tested this by using #FreeFieldNotes on a #dev mirror.
```sql
INSERT INTO "metadata"."TeamMembers" (username) VALUES ('tester'), ('monkey');

INSERT INTO "metadata"."TeamMembers" (username) VALUES ('falk');

DELETE FROM "metadata"."TeamMembers" WHERE username = 'falk';

UPDATE "inbound"."FreeFieldNotes" SET log_user = 'maintenance';

SELECT * FROM "inbound"."FreeFieldNotes";
```