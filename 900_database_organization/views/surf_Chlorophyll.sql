
DROP VIEW IF EXISTS  "inbound"."Chlorophyll" ;
CREATE VIEW "inbound"."Chlorophyll" AS
SELECT
  LOC.*,
  CHLA.chlorophyllmeasurement_id,
  CHLA.stratum,
  CHLA.iteration,
  CHLA.pool_in_rep,
  CHLA.date_first_visit,
  CHLA.infos,
  CHLA.teammember_id,
  CHLA.datetime_visit,
  CHLA.notes,
  CHLA.issues,
  CHLA.photo,
  CHLA.watertemperature_celsius,
  CHLA.torch_a_freewater_1,
  CHLA.torch_a_freewater_2,
  CHLA.torch_a_freewater_3,
  CHLA.torch_a_sample_1,
  CHLA.torch_a_sample_2,
  CHLA.torch_a_sample_3,
  CHLA.torch_b_sample_1,
  CHLA.torch_b_sample_2,
  CHLA.torch_b_sample_3,
  CHLA.fluo_a_sample_1,
  CHLA.fluo_a_sample_2,
  CHLA.fluo_a_sample_3,
  CHLA.fluo_b_sample_1,
  CHLA.fluo_b_sample_2,
  CHLA.fluo_b_sample_3,
  CHLA.samplingpoint_marked,
  CHLA.visit_done
FROM "inbound"."ChlorophyllMeasurements" AS CHLA
LEFT JOIN "metadata"."Locations" AS LOC
  ON LOC.grts_address = CHLA.grts_address
;


DROP RULE IF EXISTS Chlorophyll_upd0 ON "inbound"."Chlorophyll";
CREATE RULE Chlorophyll_upd0 AS
ON UPDATE TO "inbound"."Chlorophyll"
DO INSTEAD NOTHING
;

DROP RULE IF EXISTS Chlorophyll_upd1 ON "inbound"."Chlorophyll";
CREATE RULE Chlorophyll_upd1 AS
ON UPDATE TO "inbound"."Chlorophyll"
DO ALSO
 UPDATE "inbound"."ChlorophyllMeasurements"
 SET
  teammember_id = NEW.teammember_id,
  datetime_visit = NEW.datetime_visit,
  notes = NEW.notes,
  photo = NEW.photo,
  issues = NEW.issues,
   watertemperature_celsius = NEW.watertemperature_celsius,
   torch_a_freewater_1 = NEW.torch_a_freewater_1,
   torch_a_freewater_2 = NEW.torch_a_freewater_2,
   torch_a_freewater_3 = NEW.torch_a_freewater_3,
   torch_a_sample_1 = NEW.torch_a_sample_1,
   torch_a_sample_2 = NEW.torch_a_sample_2,
   torch_a_sample_3 = NEW.torch_a_sample_3,
   torch_b_sample_1 = NEW.torch_b_sample_1,
   torch_b_sample_2 = NEW.torch_b_sample_2,
   torch_b_sample_3 = NEW.torch_b_sample_3,
   fluo_a_sample_1 = NEW.fluo_a_sample_1,
   fluo_a_sample_2 = NEW.fluo_a_sample_2,
   fluo_a_sample_3 = NEW.fluo_a_sample_3,
   fluo_b_sample_1 = NEW.fluo_b_sample_1,
   fluo_b_sample_2 = NEW.fluo_b_sample_2,
   fluo_b_sample_3 = NEW.fluo_b_sample_3,
   samplingpoint_marked = NEW.samplingpoint_marked,
  visit_done = NEW.visit_done
 WHERE chlorophyllmeasurement_id = OLD.chlorophyllmeasurement_id
;


GRANT SELECT ON  "inbound"."Chlorophyll"  TO viewer_mnmdb;
GRANT UPDATE ON  "inbound"."Chlorophyll"  TO  user_surfdb;
