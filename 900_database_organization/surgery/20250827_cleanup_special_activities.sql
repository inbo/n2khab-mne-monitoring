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

-- then ran 901_*.R
-- -> one changed; others not linked


next steps:
-- replace all from the table above
-- check that filled data of remainder is really identical
SELECT FROM WIA where samplelocation_id does not have visits anymore;
-- ... and delete manually if irrelevant
--
-- reproduce all steps on `production`
