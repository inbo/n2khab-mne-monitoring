
-- problem: WIA and CSA got the same IDs
-- quick fix:

UPDATE "inbound"."ChemicalSamplingActivities" SET fieldwork_id = fieldwork_id + 10000;
