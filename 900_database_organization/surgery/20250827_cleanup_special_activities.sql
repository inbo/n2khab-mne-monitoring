-- OBSERVATION

SELECT
  fieldwork_id,
  log_user,
  log_update,
  samplelocation_id,
  fieldworkcalendar_id,
  visit_id,
  grts_address,
  activity_group_id,
  date_start,
  teammember_id,
  date_visit,
  visit_done
FROM "inbound"."WellInstallationActivities"
WHERE fieldworkcalendar_id IS NULL
UNION
SELECT
  fieldwork_id,
  log_user,
  log_update,
  samplelocation_id,
  fieldworkcalendar_id,
  visit_id,
  grts_address,
  activity_group_id,
  date_start,
  teammember_id,
  date_visit,
  visit_done
FROM "inbound"."ChemicalSamplingActivities"
WHERE fieldworkcalendar_id IS NULL
;


-- DELETE THE FOLLOWING
SELECT *
FROM "inbound"."WellInstallationActivities"
WHERE fieldworkcalendar_id IS NULL
  AND (teammember_id IS NULL)
  AND (date_visit IS NULL)
  AND (photo_soil_1_peilbuis IS NULL)
  AND (photo_soil_2_piezometer IS NULL)
  AND (photo_well IS NULL)
  AND (watina_code_used_1_peilbuis IS NULL)
  AND (watina_code_used_2_piezometer IS NULL)
  AND (soilprofile_notes IS NULL)
  AND (soilprofile_unclear IS NULL OR (NOT soilprofile_unclear))
  AND (random_point_number IS NULL)
  AND (no_diver IS NULL OR (NOT no_diver))
  AND (diver_id IS NULL)
  AND (free_diver IS NULL)
  AND (NOT visit_done)
;



-- delete but first check for activity
SELECT *
FROM "inbound"."Visits" AS VIS
WHERE fieldworkcalendar_id IS NULL
  AND NOT visit_done
  AND teammember_id IS NULL
;


-- delete but first check for activity
SELECT *
FROM "inbound"."ChemicalSamplingActivities"
WHERE fieldworkcalendar_id IS NULL
  AND NOT visit_done AND teammember_id IS NULL
;

-- check these:
SELECT *
FROM "inbound"."Visits" AS VIS
LEFT JOIN "archive"."ReplacementData" AS RDATA
  ON RDATA.grts_address = VIS.grts_address
WHERE fieldworkcalendar_id IS NULL
  AND NOT visit_done AND teammember_id IS NULL
  AND RDATA.grts_address_replacement IS NULL
;


SELECT *
FROM "inbound"."ChemicalSamplingActivities" AS CSA
LEFT JOIN "archive"."ReplacementData" AS RDATA
  ON RDATA.grts_address = CSA.grts_address
WHERE TRUE
  AND CSA.fieldworkcalendar_id IS NULL
  AND RDATA.grts_address_replacement IS NULL
; -- confirmed that there are no used ones


-- CLEANUP - lost replacement links

SELECT DISTINCT grts_address, grts_address_replacement
FROM
(SELECT DISTINCT grts_address, grts_address_replacement
FROM "archive"."ReplacementData"
WHERE grts_address IN
(
  SELECT DISTINCT grts_address
  FROM "inbound"."WellInstallationActivities"
  WHERE fieldworkcalendar_id IS NULL
  AND NOT (
        (teammember_id IS NULL)
    AND (date_visit IS NULL)
    AND (photo_soil_1_peilbuis IS NULL)
    AND (photo_soil_2_piezometer IS NULL)
    AND (photo_well IS NULL)
    AND (watina_code_used_1_peilbuis IS NULL)
    AND (watina_code_used_2_piezometer IS NULL)
    AND (soilprofile_notes IS NULL)
    AND (soilprofile_unclear IS NULL OR (NOT soilprofile_unclear))
    AND (random_point_number IS NULL)
    AND (no_diver IS NULL OR (NOT no_diver))
    AND (diver_id IS NULL)
    AND (free_diver IS NULL)
    AND (NOT visit_done)
    )
)) UNION
(SELECT DISTINCT grts_address, grts_address_replacement
FROM "archive"."ReplacementData"
WHERE grts_address IN
(
  SELECT DISTINCT grts_address
  FROM "inbound"."ChemicalSamplingActivities"
  WHERE fieldworkcalendar_id IS NULL
  AND NOT (
        (teammember_id IS NULL)
      AND (date_visit IS NULL)
      AND (project_code IS NULL)
      AND (recipient_code IS NULL)
      AND (NOT visit_done)
    )
));


 grts_address | grts_address_replacement
--------------+--------------------------
        17318 |                  4211622
       769793 |                  1818369
      2203766 |                 27369590
      4163858 |                 29329682
     53184786 |                 36407570


SELECT *
FROM "inbound"."WellInstallationActivities"
WHERE grts_address IN (2203766, 27369590)
;


UPDATE "inbound"."WellInstallationActivities"
SET grts_address = 27369590
WHERE grts_address = 2203766;

UPDATE "inbound"."WellInstallationActivities"
SET grts_address = 4211622
WHERE grts_address = 17318;

UPDATE "inbound"."WellInstallationActivities"
SET grts_address = 1818369
WHERE grts_address = 769793;

UPDATE "inbound"."WellInstallationActivities"
SET grts_address = 29329682
WHERE grts_address = 4163858;

UPDATE "inbound"."WellInstallationActivities"
SET grts_address = 36407570
WHERE grts_address = 53184786;

-- then ran 901_*.R
-- -> one changed; others not linked


next steps:
-- replace all from the table above

-- check that filled data of remainder is really identical
check <- dplyr::tbl(
    db_connection,
    DBI::Id(schema = "inbound", table = "WellInstallationActivities")
  ) %>%
  filter(grts_address %in% c(36407570, 29329682, 1818369, 4211622, 27369590)) %>%
  filter(is.na(fieldworkcalendar_id)) %>%
  collect

check %>% knitr::kable()

visits <- dplyr::tbl(
    db_connection,
    DBI::Id(schema = "inbound", table = "Visits")
  ) %>%
  collect

check %>% anti_join(
  visits,
  by = join_by(visit_id)
) %>%
select(-samplelocation_id) %>%
distinct %>%
knitr::kable()


SELECT *
FROM "inbound"."WellInstallationActivities"
WHERE fieldworkcalendar_id IS NULL
  AND samplelocation_id NOT IN
(
SELECT DISTINCT samplelocation_id
FROM "outbound"."SampleLocations"
);

-- ... and delete manually if irrelevant
--
-- reproduce all steps on `production`


mnmgwdb=#
SELECT *
FROM "inbound"."WellInstallationActivities"
WHERE fieldworkcalendar_id IS NULL
  AND visit_id NOT IN
(
SELECT DISTINCT visit_id
FROM "inbound"."Visits"
);


SELECT *
FROM "inbound"."WellInstallationActivities"
WHERE fieldworkcalendar_id IS NULL
  AND samplelocation_id NOT IN
(
SELECT DISTINCT samplelocation_id
FROM "outbound"."SampleLocations"
);

| fieldwork_id | log_user |         log_update         | samplelocation_id | fieldworkcalendar_id | visit_id | grts_address | activity_group_id | date_start | teammember_id | date_visit | visit_done |       photo_soil_1_peilbuis       |                photo_well                | watina_code_used_1_peilbuis | watina_code_used_2_piezometer | no_diver | diver_id |      photo_soil_2_piezometer      | free_diver | soilprofile_notes | soilprofile_unclear | random_point_number |
|--------------+----------+----------------------------+-------------------+----------------------+----------+--------------+-------------------+------------+---------------+------------+------------+-----------------------------------+------------------------------------------+-----------------------------+-------------------------------+----------+----------+-----------------------------------+------------+-------------------+---------------------+---------------------|
|         1343 | falk     | 2025-08-28 07:34:07.511411 |               749 |                      |          |     27369590 |                 4 | 2025-07-01 |             3 | 2025-08-06 | f          | DCIM/soilpb_20250806121722777.jpg | DCIM/wellplacement_20250806124750558.jpg | BUIP153X                    | BUIP053X                      | f        |          | DCIM/soilpz_20250806104641465.jpg | 1173292    |                   | f                   |                   1 |
|         1349 | falk     | 2025-08-28 07:34:07.511411 |               769 |                      |          |     27369590 |                 4 | 2025-07-01 |             3 | 2025-08-06 | f          | DCIM/soilpb_20250806121722777.jpg | DCIM/wellplacement_20250806124750558.jpg | BUIP153X                    | BUIP053X                      | f        |          | DCIM/soilpz_20250806104641465.jpg | 1173292    |                   | f                   |                   1 |
|         1620 | falk     | 2025-08-28 07:34:07.511411 |               791 |                      |          |     27369590 |                 4 | 2025-07-01 |             3 | 2025-08-06 | f          | DCIM/soilpb_20250806121722777.jpg | DCIM/wellplacement_20250806124750558.jpg | BUIP153X                    | BUIP053X                      | f        |          | DCIM/soilpz_20250806104641465.jpg | 1173292    |                   | f                   |                   1 |
|         1621 | falk     | 2025-08-28 07:34:07.511411 |               813 |                      |          |     27369590 |                 4 | 2025-07-01 |             3 | 2025-08-06 | f          | DCIM/soilpb_20250806121722777.jpg | DCIM/wellplacement_20250806124750558.jpg | BUIP153X                    | BUIP053X                      | f        |          | DCIM/soilpz_20250806104641465.jpg | 1173292    |                   | f                   |                   1 |
|         1346 | falk     | 2025-08-28 07:34:07.557843 |               777 |                      |          |     36407570 |                 4 | 2025-07-01 |             1 | 2025-08-07 | f          | DCIM/soilpb_20250807170252205.jpg | DCIM/wellplacement_20250807170405561.jpg | HAGP135X                    | HAGP135X                      | f        |          | DCIM/soilpz_20250807170300285.jpg | 1193378    |                   | f                   |                   2 |
|         1357 | falk     | 2025-08-28 07:34:07.557843 |               798 |                      |          |     36407570 |                 4 | 2025-07-01 |             1 | 2025-08-07 | f          | DCIM/soilpb_20250807170252205.jpg | DCIM/wellplacement_20250807170405561.jpg | HAGP135X                    | HAGP135X                      | f        |          | DCIM/soilpz_20250807170300285.jpg | 1193378    |                   | f                   |                   2 |
|         1622 | falk     | 2025-08-28 07:34:07.557843 |               820 |                      |          |     36407570 |                 4 | 2025-07-01 |             1 | 2025-08-07 | f          | DCIM/soilpb_20250807170252205.jpg | DCIM/wellplacement_20250807170405561.jpg | HAGP135X                    | HAGP135X                      | f        |          | DCIM/soilpz_20250807170300285.jpg | 1193378    |                   | f                   |                   2 |
(7 rows)
