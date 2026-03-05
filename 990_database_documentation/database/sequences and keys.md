---
aliases:
  - sequences
  - sequence
  - keys
  - primary key
  - foreign key
  - index
tags:
  - index
---
## Primary Keys (pk)
pk's naming convention follows the table name, without a plural `-s`, and the suffix `_id`.
For example, `TeamMembers` the pk column is `teammember_id`.

## Sequences
sequences are automatically initialized by the [[maintenance/creation|database creation]] #python script with the following syntax:
```python
f"""
CREATE SEQUENCE "{schema}".seq_{sequence_column}
  INCREMENT BY 1
  MINVALUE 0
  MAXVALUE 2147483647
  START WITH 1
  CACHE 1
  NO CYCLE
  OWNED BY "{schema}"."{table}".{sequence_column};
ALTER TABLE "{schema}"."{table}" ALTER COLUMN {sequence_column}
  SET DEFAULT nextval('{schema}.seq_{sequence_column}'::regclass);
"""
```
Sequence columns are usually the primary keys.

>[!warning] auto-increment occasionally fails
> I experienced some issues with non-auto-incrementing sequences, in some but not all `INSERT` situations.
> This might be related to either/or/and
> - `USAGE` vs. `SELECT` permissions
> - ambiguous sequence/key definition (`seq_<pk>` *versus* `<table name>_pkey`)
> - a misconfiguration in the code block above (`AUTO INCREMENT`?)

There is an option in [[R/MNMDatabaseConnection|MNMDatabaseConnection]] to set a sequence key, which also allows to reset it to `"max"` (the maximum value).

You can also manually set the next value, in case of an error.
```sql
-- ERROR:  duplicate key value violates unique constraint "<table name>_pkey"
-- DETAIL:  Key (<pk>)=(1) already exists.
ALTER SEQUENCE "metadata".seq_<primarykey_id> RESTART WITH <one more than highest value>;
```
