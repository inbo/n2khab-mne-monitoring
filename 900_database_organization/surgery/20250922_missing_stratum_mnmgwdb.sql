by the way...
mnmgwdb=# GRANT SELECT ON "inbound"."FieldFollowUps" TO monkey;
mnmgwdb=# GRANT SELECT ON "outbound"."LocationCoords" TO monkey;
mnmgwdb=# GRANT SELECT ON "outbound"."SampleCells" TO monkey;


zelf gevonden:
190802 -> 12773714
205598 -> 205598
485682 -> 17262898
1485106 -> 35039538
72238 -> 15538734
53662 -> 4772254
50354734 -> 20994606


I will manually delete:
SELECT *
FROM "inbound"."WellInstallationActivities"
WHERE stratum IS NULL;

SELECT *
FROM "inbound"."ChemicalSamplingActivities"
WHERE stratum IS NULL;



van Tom:
  219694
 1202926
 6417454
 9525806
50354734
 1999406



### tracing...

SELECT grts_address, *
FROM "outbound"."SampleLocations"
WHERE grts_address IN (
 -- 219694,
 -- 1202926,
 -- 1999406,
 -- 6417454,
 -- 9525806,
50354734
)
;

 grts_address | samplelocation_id | location_id | grts_address | scheme_ps_targetpanels | schemes | strata  | is_replacement |      domain_part      | archive_version_id
--------------+-------------------+-------------+--------------+------------------------+---------+---------+----------------+-----------------------+--------------------
      9525806 |               332 |          40 |      9525806 | GW_03.3:PS1PANEL12     | GW_03.3 | 91E0_vm | f              | BE2100024             |
      6417454 |               511 |          14 |      6417454 | GW_03.3:PS2PANEL05     | GW_03.3 | 91E0_vm | f              | SAC_network_remainder |
       219694 |               598 |         678 |       219694 | GW_03.3:PS1PANEL08     | GW_03.3 | 91E0_vo | f              | BE2100024             |
(3 rows)


SELECT
  grts_address,
  stratum,
  fieldworkcalendar_id,
  samplelocation_id,
  date_start,
  activity_group_id,
  activity_rank,
  priority,
  excluded,
  teammember_assigned,
  date_visit_planned,
  done_planning,
  archive_version_id
FROM "outbound"."FieldworkCalendar"
WHERE grts_address IN (
  219694,
 1202926,
 1999406,
 6417454,
 9525806,
50354734
)
;


 grts_address | stratum | fieldworkcalendar_id | samplelocation_id | date_start | activity_group_id | activity_rank | priority | excluded | teammember_assigned | date_visit_planned | done_planning | archive_version_id
--------------+---------+----------------------+-------------------+------------+-------------------+---------------+----------+----------+---------------------+--------------------+---------------+--------------------
       219694 | 91E0_vo |                 1324 |               598 | 2025-10-01 |                13 |             4 |        5 | f        |                     |                    | f             |                  1
       219694 | 91E0_vo |                  211 |               598 | 2025-10-01 |                11 |             3 |        5 | f        |                     |                    | f             |
       219694 | 91E0_vo |                 1323 |               598 | 2025-10-01 |                 4 |             2 |        5 | f        |                     |                    | f             |
      6417454 | 91E0_vm |                 1341 |               511 | 2026-04-01 |                28 |             3 |        2 | f        |                  11 | 2025-09-26         | t             |
      9525806 | 91E0_vm |                 1383 |               332 | 2026-10-01 |                 4 |             2 |        7 | f        |                     |                    | f             |
      6417454 | 91E0_vm |                 1340 |               511 | 2026-04-01 |                 4 |             2 |        2 | f        |                     |                    | f             |                  1
      6417454 | 91E0_vm |                 1364 |               511 | 2026-07-01 |                 9 |             3 |        2 | f        |                     |                    | f             |                  1
       219694 | 91E0_vo |                 1333 |               598 | 2025-10-01 |                28 |             3 |        5 | f        |                     |                    | f             |                  1
       219694 | 91E0_vo |                 1338 |               598 | 2026-04-01 |                 9 |             3 |        5 | f        |                     |                    | f             |                  1
       219694 | 91E0_vo |                 1362 |               598 | 2026-10-01 |                 9 |             3 |        5 | f        |                     |                    | f             |                  1
      9525806 | 91E0_vm |                 1390 |               332 | 2026-10-01 |                28 |             3 |        7 | f        |                     |                    | f             |                  1
(11 rows)


  219694 -> found
 1202926 -> found
 6417454 -> found
 9525806 -> found
50354734 -> verv. 20994606

53438326 -> loc 4 selected (576326390)


(using 080 grts dashboard)


# 1999406 -> verv. 6417454
- not seen in planning <- reason: `archive_version_id` was set
- 1999406 LocationInfo left -> update

SELECT * FROM "outbound"."SampleLocations" WHERE grts_address = 6417454;
-- (good)

SELECT * FROM "outbound"."FieldworkCalendar" WHERE grts_address = 6417454;
UPDATE "outbound"."FieldworkCalendar"
  SET archive_version_id = NULL
  WHERE grts_address = 6417454;


SELECT * FROM "inbound"."Visits" WHERE grts_address = 6417454;
UPDATE "inbound"."Visits"
  SET archive_version_id = NULL
  WHERE grts_address = 6417454;



--------------------------------------------------------------------------------

SELECT grts_address, *
FROM "outbound"."SampleLocations"
WHERE grts_address IN (
 9525806, 219694
)
;


... does NOT appear any more in the calendar
BUT was a replacement 219694 -> 9525806
    with another type in the same cell!

219694, 91E0_vo -> 219694 no replacement
219694, 91E0_vm -> 9525806, 91E0_vm

SELECT grts_address, *
FROM "outbound"."SampleLocations"
WHERE grts_address IN (219694, 9525806)
;

SELECT grts_address, *
FROM "outbound"."FieldworkCalendar"
WHERE grts_address IN (219694, 9525806)
;
-- wow something went wrong there


UPDATE "outbound"."SampleLocations"
  SET archive_version_id = NULL
WHERE grts_address = 219694;
WHERE grts_address = 9525806;

UPDATE "outbound"."FieldworkCalendar"
  SET archive_version_id = NULL
WHERE grts_address = 219694;
WHERE grts_address = 9525806;

UPDATE "inbound"."Visits"
  SET archive_version_id = NULL
WHERE grts_address = 219694;
WHERE grts_address = 9525806;



--------------------------------------------------------------------------------
-- 1202926, 6230_hmo
-- replaced: 10640110, 6230_hmo

SELECT grts_address, *
FROM "outbound"."SampleLocations"
WHERE grts_address IN (10640110, 1202926)
;

UPDATE "outbound"."FieldworkCalendar"
  SET archive_version_id = NULL
WHERE grts_address = 10640110;

UPDATE "inbound"."Visits"
  SET archive_version_id = NULL
WHERE grts_address = 10640110;


SELECT grts_address, *
FROM "outbound"."FieldworkCalendar"
WHERE grts_address IN (10640110, 1202926)
;

--------------------------------------------------------------------------------
-- 50354734, 7140_oli (Karen)
-- replaced to 20994606, 7140_oli (Karen)

SELECT grts_address, *
FROM "archive"."ReplacementData"
WHERE grts_address IN (50354734)
;

SELECT grts_address, *
FROM "outbound"."SampleLocations"
WHERE grts_address IN (20994606, 50354734)
;


UPDATE "outbound"."FieldworkCalendar"
  SET archive_version_id = NULL
WHERE grts_address IN (20994606, 50354734)
;

UPDATE "inbound"."Visits"
  SET archive_version_id = NULL
WHERE grts_address IN (20994606, 50354734)
;


SELECT grts_address, *
FROM "outbound"."FieldworkCalendar"
WHERE grts_address IN (20994606, 50354734)
;


--------------------------------------------------------------------------------
-- 253621 -> 4447925, 1330_da

SELECT grts_address, *
FROM "outbound"."SampleLocations"
WHERE grts_address IN (253621, 4447925)
;

UPDATE "outbound"."FieldworkCalendar"
  SET archive_version_id = NULL
WHERE grts_address IN (253621, 4447925)
;

UPDATE "inbound"."Visits"
  SET archive_version_id = NULL
WHERE grts_address IN (253621, 4447925)
;

SELECT grts_address, *
FROM "outbound"."FieldworkCalendar"
WHERE grts_address IN (253621, 4447925)
;

--------------------------------------------------------------------------------

SELECT * FROM (
  SELECT DISTINCT grts_address, stratum, COUNT(archived) AS n
  FROM (
    SELECT DISTINCT
      grts_address,
      stratum,
      (NOT archive_version_id IS NULL) AS archived
    FROM "outbound"."FieldworkCalendar"
    GROUP BY grts_address, stratum, archived
    ORDER BY stratum, grts_address, archived
  ) AS FWCAL
  GROUP BY grts_address, stratum
  ORDER BY grts_address, stratum
)
WHERE n > 1
;


SELECT grts_address, *
FROM "outbound"."FieldworkCalendar"
WHERE grts_address IN (83694)
;



Ambiguous:
         7465 | 91E0_vn     | 2
        15937 | 91E0_vn     | 2
        19238 | 9160        | 2
        23238 | 9160        | 2
        48897 | 6230_hmo    | 2
        83694 | 9190        | 2
       155346 | 91E0_vo     | 2
       421762 | 9160        | 2
       541570 | 91E0_va     | 2
       871858 | 3260        | 2
      1176286 | 4010        | 2
      1284318 | 3160_0_1    | 2
      1363273 | 6430_mr     | 2
      1514726 | 91E0_va     | 2
      1675858 | 3110_1_5    | 2
      1675858 | 3130_na_1_5 | 2
      2462430 | 3160_1_5    | 2
      4241542 | 91E0_vm     | 2
      6075038 | 6230_hmo    | 2
      6314694 | 91E0_va     | 2
      9424086 | 6230_hmo    | 2
     13038894 | 7150        | 2
     14026450 | 3110_1_5    | 2
     15538734 | 7150        | 2
     17682598 | 6410_mo     | 2
     17912057 | 91E0_vn     | 2
     18986217 | 91E0_sf     | 2
     20807190 | 3140_50_150 | 2
     21323197 | 1310_pol    | 2
     29769397 | 1310_pol    | 2
     30400902 | 7140_base   | 2
     33958194 | 3140_1_5    | 2
     39213362 | 7150        | 2
     42070750 | 7140_oli    | 2
     42807442 | 3150_1_5    | 2
     43623186 | 6410_ve     | 2
     47517086 | 6510_hus    | 2
     50459358 | 3160_1_5    | 2
     53206450 | 9130_fm     | 2
     60185305 | 91E0_va     | 2



UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 7465 AND stratum = '91E0_vn'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 15937 AND stratum = '91E0_vn'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 19238 AND stratum = '9160'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 23238 AND stratum = '9160'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 48897 AND stratum = '6230_hmo'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 83694 AND stratum = '9190'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 155346 AND stratum = '91E0_vo'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 421762 AND stratum = '9160'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 541570 AND stratum = '91E0_va'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 871858 AND stratum = '3260'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 1176286 AND stratum = '4010'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 1284318 AND stratum = '3160_0_1'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 1363273 AND stratum = '6430_mr'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 1514726 AND stratum = '91E0_va'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 1675858 AND stratum = '3110_1_5'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 1675858 AND stratum = '3130_na_1_5'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 2462430 AND stratum = '3160_1_5'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 4241542 AND stratum = '91E0_vm'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 6075038 AND stratum = '6230_hmo'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 6314694 AND stratum = '91E0_va'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 9424086 AND stratum = '6230_hmo'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 13038894 AND stratum = '7150'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 14026450 AND stratum = '3110_1_5'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 15538734 AND stratum = '7150'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 17682598 AND stratum = '6410_mo'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 17912057 AND stratum = '91E0_vn'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 18986217 AND stratum = '91E0_sf'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 20807190 AND stratum = '3140_50_150'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 21323197 AND stratum = '1310_pol'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 29769397 AND stratum = '1310_pol'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 30400902 AND stratum = '7140_base'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 33958194 AND stratum = '3140_1_5'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 39213362 AND stratum = '7150'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 42070750 AND stratum = '7140_oli'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 42807442 AND stratum = '3150_1_5'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 43623186 AND stratum = '6410_ve'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 47517086 AND stratum = '6510_hus'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 50459358 AND stratum = '3160_1_5'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 53206450 AND stratum = '9130_fm'
;

UPDATE "outbound"."FieldworkCalendar" SET archive_version_id = NULL
WHERE grts_address = 60185305 AND stratum = '91E0_va'
;


--------------------------------------------------------------------------------

SELECT DISTINCT
  FWCAL.grts_address,
  FWCAL.stratum,
  FWCAL.archive_version_id,
  REP.grts_address_poc
FROM "outbound"."FieldworkCalendar" AS FWCAL
LEFT JOIN (
  SELECT DISTINCT
    grts_address AS grts_address_poc,
    type AS stratum,
    grts_address_replacement AS grts_address
  FROM "archive"."ReplacementData"
) AS REP
  ON REP.grts_address = FWCAL.grts_address
WHERE archive_version_id IS NOT NULL
GROUP BY FWCAL.grts_address, FWCAL.stratum, archive_version_id, grts_address_poc
ORDER BY FWCAL.stratum, FWCAL.grts_address, archive_version_id, grts_address_poc
;


 grts_address | stratum  | archive_version_id | grts_address_poc
--------------+----------+--------------------+------------------
     19914421 | 1310_pol |                  1 |          5234357
     10152242 | 4010     |                  1 |           649522
     14543154 | 7140_oli |                  1 |          9300274
      9478930 | 91E0_vm  |                  1 |            41746
(4 rows)


Confirmed: these are still in the POC/calendar.

SELECT * FROM "outbound"."FieldworkCalendar"
"outbound"."FieldworkCalendar"
"inbound"."Visits"
UPDATE
SET archive_version_id = NULL
WHERE FALSE
   OR (grts_address = 19914421 AND stratum = '1310_pol')
   OR (grts_address = 10152242 AND stratum = '4010' )
   OR (grts_address = 14543154 AND stratum = '7140_oli')
   OR (grts_address =  9478930 AND stratum = '91E0_vm')
;

--------------------------------------------------------------------------------
-- more found when continuing the consistency dashboard


mnmgwdb=> SELECT grts_address, *
FROM "outbound"."SampleLocations"
WHERE grts_address IN (10119474)
;
 grts_address | samplelocation_id | location_id | grts_address |   scheme_ps_targetpanels    |     schemes      |  strata  | is_replacement | domain_part | archive_version_id
--------------+-------------------+-------------+--------------+-----------------------------+------------------+----------+----------------+-------------+--------------------
     10119474 |               776 |         795 |     10119474 | SURF_03.4_lentic:PS1PANEL03 | SURF_03.4_lentic | 3150_0_1 | f              | BE2200028   |                  1
(1 row)

this is the wrong scheme; well archived!

-- DELETE
SELECT *
FROM "metadata"."LocationCells"
WHERE grts_address = 10119474;

FROM "metadata"."Locations"
FROM "metadata"."LocationCells"
FROM "outbound"."SampleLocations"
FROM "outbound"."FieldworkCalendar"
FROM "inbound"."Visits"
FROM "inbound"."ChemicalSamplingActivities"
FROM "inbound"."WellInstallationActivities"

SELECT * FROM "outbound"."LocationInfos" WHERE grts_address = 10119474;
SELECT * FROM "metadata"."Coordinates" WHERE grts_address = 10119474;
  grts_address,
  stratum,
  archive_version_id
FROM "outbound"."FieldworkCalendar"
WHERE archive_version_id IS NOT NULL
GROUP BY FWCAL.grts_address, FWCAL.stratum, archive_version_id, grts_address_poc
ORDER BY FWCAL.stratum, FWCAL.grts_address, archive_version_id, grts_address_poc
;


 grts_address | stratum  | archive_version_id | grts_address_poc
--------------+----------+--------------------+------------------
     19914421 | 1310_pol |                  1 |          5234357
     10152242 | 4010     |                  1 |           649522
     14543154 | 7140_oli |                  1 |          9300274
      9478930 | 91E0_vm  |                  1 |            41746
(4 rows)


Confirmed: these are still in the POC/calendar.

SELECT * FROM "outbound"."FieldworkCalendar"
"outbound"."FieldworkCalendar"
"inbound"."Visits"
UPDATE
SET archive_version_id = NULL
WHERE FALSE
   OR (grts_address = 19914421 AND stratum = '1310_pol')
   OR (grts_address = 10152242 AND stratum = '4010' )
   OR (grts_address = 14543154 AND stratum = '7140_oli')
   OR (grts_address =  9478930 AND stratum = '91E0_vm')
;

--------------------------------------------------------------------------------
-- more found when continuing the consistency dashboard


mnmgwdb=> SELECT grts_address, *
FROM "outbound"."SampleLocations"
WHERE grts_address IN (10119474)
;
 grts_address | samplelocation_id | location_id | grts_address |   scheme_ps_targetpanels    |     schemes      |  strata  | is_replacement | domain_part | archive_version_id
--------------+-------------------+-------------+--------------+-----------------------------+------------------+----------+----------------+-------------+--------------------
     10119474 |               776 |         795 |     10119474 | SURF_03.4_lentic:PS1PANEL03 | SURF_03.4_lentic | 3150_0_1 | f              | BE2200028   |                  1
(1 row)

this is the wrong scheme; well archived!

-- DELETE
SELECT *
FROM "metadata"."LocationCells"
WHERE grts_address = 10119474;

FROM "metadata"."Locations"
FROM "metadata"."LocationCells"
FROM "outbound"."SampleLocations"
FROM "outbound"."FieldworkCalendar"
FROM "inbound"."Visits"
FROM "inbound"."ChemicalSamplingActivities"
FROM "inbound"."WellInstallationActivities"

SELECT * FROM "outbound"."LocationInfos" WHERE grts_address = 10119474;
SELECT * FROM "metadata"."Coordinates" WHERE grts_address = 10119474;
-- DONE
