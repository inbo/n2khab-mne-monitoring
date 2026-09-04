
-- problem: WIA and CSA got the same IDs
-- quick fix:

SELECT * FROM "inbound"."ChemicalSamplingActivities" ORDER BY fieldwork_id ASC;

SELECT *
FROM "inbound"."WellInstallationActivities" AS WIA
LEFT JOIN "inbound"."ChemicalSamplingActivities" AS CSA
  ON (WIA.fieldwork_id = CSA.fieldwork_id)
WHERE WIA.fieldwork_id = CSA.fieldwork_id
;

[!]
UPDATE "inbound"."ChemicalSamplingActivities"
  SET fieldwork_id = fieldwork_id + 10000
  WHERE fieldwork_id < 9999
;
