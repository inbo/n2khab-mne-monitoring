---
tags:
  - sql
  - functions
aliases:
  - functions
---
An example for an sql function which we actually use (slightly modified):
```sql
CREATE OR REPLACE FUNCTION "metadata".sync_mod(disable BOOLEAN)
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

  IF is_teammember AND NOT disable THEN
    NEW.log_update := current_timestamp;
    NEW.log_user := current_user;
  END IF;

  RETURN NEW
  ;
END;
$sync_mod$
LANGUAGE plpgsql;

```

+ `CREATE OR REPLACE` spares a `DROP IF EXISTS` and many cascaded trigger drops
+ The function signature can immediately declare variable types (e.g. `diable BOOLEAN`) or work with numbered input (`$1, $2`).
+ `RETURNS` preregisters the output type
+ `$$` is a block; the block name is optional between dollar signs (here: `$sync_mod$)
+ `DECLARE` can declare variable names - separated by semicolons.
+ `DECLARE ... ALIAS` (not shown) can alias a numbered input argument (e.g. `DECLARE a_word ALIAS FOR $1; startPos ALIAS FOR $2;`)
+ `BEGIN ... END;` wraps the function.
+ `LANGUAGE plpgsql;` is the only language I know.
