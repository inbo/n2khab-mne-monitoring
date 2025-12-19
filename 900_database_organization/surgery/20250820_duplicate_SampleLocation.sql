SELECT DISTINCT grts_address, count(*) AS n
FROM "outbound"."SampleLocations"
GROUP BY grts_address
ORDER BY n DESC;


 grts_address | n
--------------+---
     60185305 | 2
         5705 | 1

SELECT * FROM "outbound"."SampleLocations" WHERE grts_address =  60185305;

 samplelocation_id | location_id | grts_address | scheme_ps_targetpanels | schemes | strata  | is_replacem
ent
-------------------+-------------+--------------+------------------------+---------+---------+------------
----
               597 |         597 |     60185305 | GW_03.3:PS1PANEL11     | GW_03.3 | 91E0_va | t
               837 |         597 |     60185305 | GW_03.3:PS1PANEL11     | GW_03.3 | 91E0_va | t
(2 rows)


-- location appears in "archive"."ReplacementData":
SELECT * FROM "archive"."ReplacementData" WHERE new_samplelocation_id = 837;

 replacementdata_id |  type   | grts_address | grts_address_replacement | replacement_rank | is_replaced | new_location_id | new_samplelocation_id
--------------------+---------+--------------+--------------------------+------------------+-------------+-----------------+-----------------------
                407 | 91E0_va |        23257 |                 60185305 |                3 | t           |             597 |                   837
(1 row)


-- no fieldwork planning in mnmgwdb
SELECT * FROM "outbound"."FieldworkPlanning" WHERE grts_address =  60185305;

-- ... but in the original calendar
fieldwork_2025_prioritization_by_stratum %>% filter(grts_address == 23257)


--> has to be re-established later.
DELETE FROM "outbound"."SampleLocations" WHERE samplelocation_id = 597;


# Rscript 033_populate_testing_db.R
