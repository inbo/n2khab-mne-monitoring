---
aliases:
tags:
  - mnmgwdb
  - rename
  - redirection
  - mnmsurfdb
started:
finished:
execution:
status: false
priority:
---

*cf.* [[structure/consistent table and field names across databases summer 2026]]

+ `DROP VIEW IF EXISTS "outbound"."SampleLocations";`
	+ also rename constraints on the renamed table
	+ ```sql
     DROP VIEW IF EXISTS "outbound"."SampleLocations";
     \d+ "outbound"."SampleUnits";
     
     BEGIN;
      ALTER TABLE "outbound"."SampleUnits" RENAME CONSTRAINT "SampleLocations_pkey" TO "SampleUnits_pkey";
      ALTER TABLE "outbound"."SampleUnits" RENAME CONSTRAINT "SampleLocations_grts_address_check" TO "SampleUnits_grts_address_check";
      ALTER TABLE "outbound"."SampleUnits" RENAME CONSTRAINT "fk_versions_samplelocations" TO "fk_versions_sampleunits";
      ALTER TABLE "outbound"."SampleUnits" RENAME CONSTRAINT "SampleLocations_samplelocation_id_not_null" TO "SampleUnits_sampleunit_id_not_null";
      ALTER TABLE "outbound"."SampleUnits" RENAME CONSTRAINT "SampleLocations_grts_address_not_null" TO "SampleUnits_grts_address_not_null";
      ALTER TABLE "outbound"."SampleUnits" RENAME CONSTRAINT "SampleLocations_schemes_not_null" TO "SampleUnits_schemes_not_null";
      ALTER TABLE "outbound"."SampleUnits" RENAME CONSTRAINT "SampleLocations_strata_not_null" TO "SampleUnits_stratum_not_null";
      ALTER TABLE "outbound"."SampleUnits" RENAME CONSTRAINT "SampleLocations_is_forest_not_null" TO "SampleUnits_is_forest_not_null";
      ALTER TABLE "outbound"."SampleUnits" RENAME CONSTRAINT "SampleLocations_is_replacement_not_null" TO "SampleUnits_is_replacement_not_null";
      ALTER TABLE "outbound"."SampleUnits" RENAME CONSTRAINT "SampleLocations_in_mhq_samples_not_null" TO "SampleUnits_in_mhq_samples_not_null";
      ALTER TABLE "outbound"."SampleUnits" RENAME CONSTRAINT "SampleLocations_has_mhq_assessment_not_null" TO "SampleUnits_has_mhq_assessment_not_null";

     COMMIT;
     
     ```
+ remove alias column `strata` from `gw_FieldWork.sql` and `gw_FieldworkPlanning.sql`
+ `DROP VIEW IF EXISTS  "outbound"."FieldworkCalendar";`
+ `DROP VIEW IF EXISTS "outbound"."RandomPoints";`
	+ ```sql
	BEGIN;
      ALTER TABLE "outbound"."InstallationPoints" RENAME CONSTRAINT "pk_randompoints_fid" TO "pk_installationpoints_fid";
      ALTER TABLE "outbound"."InstallationPoints" RENAME CONSTRAINT "RandomPoints_randompoint_id_key" TO "InstallationPoints_randompoint_id_key";
      ALTER TABLE "outbound"."InstallationPoints" RENAME CONSTRAINT "randompoints_wkb_geometry_geom_idx" TO "installationpoints_wkb_geometry_geom_idx";
      ALTER TABLE "outbound"."InstallationPoints" RENAME CONSTRAINT "RandomPoints_grts_address_check" TO "InstallationPoints_grts_address_check";
      ALTER TABLE "outbound"."InstallationPoints" RENAME CONSTRAINT "RandomPoints_ogc_fid_not_null" TO "InstallationPoints_ogc_fid_not_null";
      ALTER TABLE "outbound"."InstallationPoints" RENAME CONSTRAINT "RandomPoints_randompoint_id_not_null" TO "InstallationPoints_randompoint_id_not_null";
      ALTER TABLE "outbound"."InstallationPoints" RENAME CONSTRAINT "RandomPoints_grts_address_not_null" TO "InstallationPoints_grts_address_not_null";
      ALTER TABLE "outbound"."InstallationPoints" RENAME CONSTRAINT "RandomPoints_random_point_rank_not_null" TO "InstallationPoints_random_point_rank_not_null";
	  ALTER SEQUENCE outbound.seq_randompoint_id RENAME TO seq_installationpoint_id;
      ALTER SEQUENCE "outbound"."RandomPoints_ogc_fid_seq" RENAME TO "InstallationPoints_ogc_fid_seq";
	COMMIT;
      ```
+ `DROP VIEW IF EXISTS "outbound"."CellMaps";`
+ `DROP VIEW IF EXISTS "outbound"."LocationEvaluations";`
+ `DROP VIEW IF EXISTS "outbound"."RandomCellPoints" CASCADE;`
 +  in fieldwork(planning) view FWCAL.fieldcalendar_id AS fieldworkcalendar_id,
 

While at it, also check:
```
GeoObservations
TerraBioObservations
AquaBioObservations
LanduseObservations
```