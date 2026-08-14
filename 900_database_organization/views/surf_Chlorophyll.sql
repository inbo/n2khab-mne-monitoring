
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
  CHLA.torch_bregt_freewater1_totalchl,
  CHLA.torch_bregt_freewater1_cyano,
  CHLA.torch_bregt_freewater1_turb,
  CHLA.torch_bregt_freewater2_totalchl,
  CHLA.torch_bregt_freewater2_cyano,
  CHLA.torch_bregt_freewater2_turb,
  CHLA.torch_bregt_freewater3_totalchl,
  CHLA.torch_bregt_freewater3_cyano,
  CHLA.torch_bregt_freewater3_turb,
  CHLA.torch_bregt_bucket1_totalchl,
  CHLA.torch_bregt_bucket1_cyano,
  CHLA.torch_bregt_bucket1_turb,
  CHLA.torch_bregt_bucket2_totalchl,
  CHLA.torch_bregt_bucket2_cyano,
  CHLA.torch_bregt_bucket2_turb,
  CHLA.torch_bregt_bucket3_totalchl,
  CHLA.torch_bregt_bucket3_cyano,
  CHLA.torch_bregt_bucket3_turb,
  CHLA.torch_kul_bucket1_totalchl,
  CHLA.torch_kul_bucket1_cyano,
  CHLA.torch_kul_bucket1_turb,
  CHLA.torch_kul_bucket2_totalchl,
  CHLA.torch_kul_bucket2_cyano,
  CHLA.torch_kul_bucket2_turb,
  CHLA.torch_kul_bucket3_totalchl,
  CHLA.torch_kul_bucket3_cyano,
  CHLA.torch_kul_bucket3_turb,
  CHLA.fluo_ldm_cuvet1_chl,
  CHLA.fluo_ldm_cuvet1_pc,
  CHLA.fluo_ldm_turb_cuvet1_turb,
  CHLA.fluo_ldm_turb_cuvet1_chl,
  CHLA.fluo_ldm_cuvet2_chl,
  CHLA.fluo_ldm_cuvet2_pc,
  CHLA.fluo_ldm_turb_cuvet2_turb,
  CHLA.fluo_ldm_turb_cuvet2_chl,
  CHLA.fluo_ldm_cuvet3_chl,
  CHLA.fluo_ldm_cuvet3_pc,
  CHLA.fluo_ldm_turb_cuvet3_turb,
  CHLA.fluo_ldm_turb_cuvet3_chl,
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
    torch_bregt_freewater1_totalchl = NEW.torch_bregt_freewater1_totalchl,
    torch_bregt_freewater1_cyano = NEW.torch_bregt_freewater1_cyano,
    torch_bregt_freewater1_turb = NEW.torch_bregt_freewater1_turb,
    torch_bregt_freewater2_totalchl = NEW.torch_bregt_freewater2_totalchl,
    torch_bregt_freewater2_cyano = NEW.torch_bregt_freewater2_cyano,
    torch_bregt_freewater2_turb = NEW.torch_bregt_freewater2_turb,
    torch_bregt_freewater3_totalchl = NEW.torch_bregt_freewater3_totalchl,
    torch_bregt_freewater3_cyano = NEW.torch_bregt_freewater3_cyano,
    torch_bregt_freewater3_turb = NEW.torch_bregt_freewater3_turb,
    torch_bregt_bucket1_totalchl = NEW.torch_bregt_bucket1_totalchl,
    torch_bregt_bucket1_cyano = NEW.torch_bregt_bucket1_cyano,
    torch_bregt_bucket1_turb = NEW.torch_bregt_bucket1_turb,
    torch_bregt_bucket2_totalchl = NEW.torch_bregt_bucket2_totalchl,
    torch_bregt_bucket2_cyano = NEW.torch_bregt_bucket2_cyano,
    torch_bregt_bucket2_turb = NEW.torch_bregt_bucket2_turb,
    torch_bregt_bucket3_totalchl = NEW.torch_bregt_bucket3_totalchl,
    torch_bregt_bucket3_cyano = NEW.torch_bregt_bucket3_cyano,
    torch_bregt_bucket3_turb = NEW.torch_bregt_bucket3_turb,
    torch_kul_bucket1_totalchl = NEW.torch_kul_bucket1_totalchl,
    torch_kul_bucket1_cyano = NEW.torch_kul_bucket1_cyano,
    torch_kul_bucket1_turb = NEW.torch_kul_bucket1_turb,
    torch_kul_bucket2_totalchl = NEW.torch_kul_bucket2_totalchl,
    torch_kul_bucket2_cyano = NEW.torch_kul_bucket2_cyano,
    torch_kul_bucket2_turb = NEW.torch_kul_bucket2_turb,
    torch_kul_bucket3_totalchl = NEW.torch_kul_bucket3_totalchl,
    torch_kul_bucket3_cyano = NEW.torch_kul_bucket3_cyano,
    torch_kul_bucket3_turb = NEW.torch_kul_bucket3_turb,
    fluo_ldm_cuvet1_chl = NEW.fluo_ldm_cuvet1_chl,
    fluo_ldm_cuvet1_pc = NEW.fluo_ldm_cuvet1_pc,
    fluo_ldm_turb_cuvet1_turb = NEW.fluo_ldm_turb_cuvet1_turb,
    fluo_ldm_turb_cuvet1_chl = NEW.fluo_ldm_turb_cuvet1_chl,
    fluo_ldm_cuvet2_chl = NEW.fluo_ldm_cuvet2_chl,
    fluo_ldm_cuvet2_pc = NEW.fluo_ldm_cuvet2_pc,
    fluo_ldm_turb_cuvet2_turb = NEW.fluo_ldm_turb_cuvet2_turb,
    fluo_ldm_turb_cuvet2_chl = NEW.fluo_ldm_turb_cuvet2_chl,
    fluo_ldm_cuvet3_chl = NEW.fluo_ldm_cuvet3_chl,
    fluo_ldm_cuvet3_pc = NEW.fluo_ldm_cuvet3_pc,
    fluo_ldm_turb_cuvet3_turb = NEW.fluo_ldm_turb_cuvet3_turb,
    fluo_ldm_turb_cuvet3_chl = NEW.fluo_ldm_turb_cuvet3_chl,
   samplingpoint_marked = NEW.samplingpoint_marked,
  visit_done = NEW.visit_done
 WHERE chlorophyllmeasurement_id = OLD.chlorophyllmeasurement_id
;


GRANT SELECT ON  "inbound"."Chlorophyll"  TO viewer_mnmdb;
GRANT UPDATE ON  "inbound"."Chlorophyll"  TO  user_surfdb;
