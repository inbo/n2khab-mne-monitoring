---
aliases:
tags:
  - Locations
  - empty_geometry
  - update_cascade_lookup
started: 2026-05-11
finished: 2026-05-11
execution:
  - FM
status: true
---


request by #TDD (via chat)

some replacements seem to be unlinked to the target cells
+ `1118141, 12592278, 1751026, 18877110, 18904222, 29258198, 4232849, 46144489, 46289966, 55049430, 5848641, 6490745, 7853673, 8419481`
```sql
        \COPY (
        SELECT * FROM "outbound"."Replacements" WHERE grts_address_replacement IN (
          1118141, 12592278, 1751026, 18877110,
          18904222, 29258198, 4232849, 46144489,
          46289966, 55049430, 5848641, 6490745,
          7853673, 8419481)
        ) TO '~/dump.csv' DELIMITER ',' CSV HEADER;
```

+ `SELECT * FROM "metadata"."Locations" WHERE grts_address IN (2742, 18877110);` 
	+ gives weird `wkb_geometry`: the replacement seems to be empty bits 
	+ -> attempting [[procedures/REP update|REP update]] to fix this

## quick global fix
**solved:** locations do not work well with `redistribute_calendar_data(...)` 
-> they must be re-uploaded each time
-> switched to #update_cascade_lookup

```r
locations_lookup <- update_cascade_lookup(
  table_label = "Locations",
  new_data = locations,
  index_columns = c("location_id"),
  characteristic_columns = c("grts_address"),
  tabula_rasa = FALSE,
  verbose = TRUE
)

```

(Also applied to loceval, just to make sure; but there should have been no empty geoms.)


## **Core Issue** was in `111a_push_loceval_to_mnmgwdb.R`:

+ previously did not re-apply #grts_mh for upload of new replacements
+ fixed now by additional `add_point_coords_grts`
+ post-processing: re-ran all daily scripts