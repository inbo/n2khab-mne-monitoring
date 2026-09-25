---
tags:
  - postgis
  - geometry
---

<https://postgis.net/docs/AddGeometryColumn.html>
```sql
SELECT f_table_name As tbl, f_geometry_column As col_name, type, srid, coord_dimension As ndims
    FROM geometry_columns
;
```