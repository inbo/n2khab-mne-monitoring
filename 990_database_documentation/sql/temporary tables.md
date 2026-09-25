---
aliases:
  - temptable update
  - temptables
tags:
  - temptables
  - update
  - sql
---
*PostgreSQL features the use of temporary tables.*

> [!important] `UPDATE ... FROM temp_table`
> Temporary tables work extraordinarily well with [[sql/UPDATE... FROM|UPDATE... FROM]] .


They can be created from R:
```r
DBI::dbWriteTable(
  connection,
  name = srctab,
  value = new_date,
  overwrite = TRUE,
  temporary = TRUE # !
)

# [...]

# strictly, cleanup is not necessary
execute_sql(glue::glue("DROP TABLE {srctab};"))

```

Or used in SQL directly (<https://www.postgresql.org/docs/current/sql-createtable.html#SQL-CREATETABLE-TEMPORARY>).
