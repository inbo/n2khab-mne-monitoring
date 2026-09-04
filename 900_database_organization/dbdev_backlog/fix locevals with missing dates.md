---
aliases:
tags:
started:
finished:
execution:
status: false
---

there are locevals without name or date.
```sql
SELECT * FROM "outbound"."gwTransfer" WHERE eval_name IS NULL OR eval_date IS NULL;
  log_user  |         log_update         |      schemes      |  type   | grts_address_original | grts_address | date_start | type_assessed | type_
is_absent | eval_source | eval_name | eval_date  | eval_id | notes | photo 
------------+----------------------------+-------------------+---------+-----------------------+--------------+------------+---------------+------
----------+-------------+-----------+------------+---------+-------+-------
 salamandra | 2026-05-18 07:21:10.371482 | GW_03.3           | 7150    |              31910194 |     31910194 | 2025-05-01 | 4010          | t    
          | loceval     |           | 2025-09-04 |    1523 |       | 
 salamandra | 2026-05-18 07:21:10.371482 | GW_03.3|SOIL_03.2 | 7150    |                 84598 |       871030 | 2026-05-01 |               | f    
          | loceval     |           |            |     129 |       | 
 salamandra | 2026-05-18 07:21:10.371482 | GW_03.3|SOIL_03.2 | 9160    |                 22726 |        22726 | 2026-03-15 |               | t    
          | loceval     |           |            |    1577 |       | 
 salamandra | 2026-05-18 07:21:10.371482 | GW_03.3|SOIL_03.2 | 91E0_vm |               1999286 |      1999286 | 2026-03-15 |               | f    
          | loceval     |           |            |    1017 |       | 
(4 rows)
```