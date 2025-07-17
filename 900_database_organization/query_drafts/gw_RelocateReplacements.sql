-- FYI

SELECT
  UNIT.sampleunit_id,
  UNIT.grts_address,
  REP.grts_address_replacement
FROM "outbound"."Replacements" AS REP
LEFT JOIN "outbound"."SampleUnits" AS UNIT
  ON UNIT.sampleunit_id = REP.sampleunit_id
WHERE REP.is_selected
  AND NOT REP.is_inappropriate
  AND UNIT.is_replaced
;
