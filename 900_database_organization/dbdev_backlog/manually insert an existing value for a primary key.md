---
aliases:
tags:
started:
finished:
execution:
status: false
---

Occurred during [[qgis/features of inherited tables cannot be deleted via QGIS|the qgis feature deletion issue for inherited tables]].

When inserting a database entry with explicitly setting an existing key column, that will create a duplicate in the key column.
This is despite the fact that the key column is set to be `UNIQUE`: the child table does not enter the uniqueness check.

```sql
-- basic issue: duplicate primary keys! (because they are not really PKs)

INSERT INTO bananas (wkb_geometry) VALUES ('01010000208A7A0000BAE74DCD228EF94062E5417B2E970F41');

INSERT INTO fruits (wkb_geometry, fruit_id) VALUES ('01010000208A7A0000BAE74DCD228EF94062E5417B2E970F41', 2);

sandbox=> SELECT * FROM fruits;
 ogc_fid |                    wkb_geometry                    | fruit_id
---------+----------------------------------------------------+----------
       3 | 01010000208A7A0000BAE74DCD228EF94062E5417B2E970F41 |        2
       2 | 01010000208A7A0000BAE74DCD228EF94062E5417B2E970F41 |        2
(2 rows)

sandbox=> :(



```



I wonder whether this can happen with `ogc_fid` and what implications that would have upon feature deletion.
