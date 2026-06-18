---
aliases:
tags:
  - Visits
  - inheritance
  - TerrestrialTypesVisits
  - AquaticTypesVisits
  - renaming
started: 2026-06-18
finished:
execution:
  - FM
status: false
---

There are #Visits already, but historically these are just `TerrestrialVisits`.

> [!warning] Temporal Polymorphism
> For repeated testing, structure sheets may deviate; however, there is only one google sheet master which gets adjusted without being properly version controlled.
> 
> - best execute this task without interruption
> - the _production_ db structure sheet **must** remain unaltered -> for `-staging` and `-production`
> - the _dev_ structure sheet will deviate -> for `-dev` and `-testing`; transient application to `-staging`
> 
> Remember that extraction of structure tables happens on a git branch; maintenance work can happen on another one.


strategy, modified from [[procedures/steps to rename a table and columns|steps to rename a table and columns]]:
+ rename or drop constraints on the table
+ rename existing `Visits` to `PreservedVisits` to preserve the data
+ establish altered structure
	+ by `python 501_init_loceval.py > dump.txt`
+ then insert into `*Visits` FROM PreservedVisits based on `activity_group_id`
+ check and possibly restore downstream constraints
+ check and adjust #views
+ check all maintenance scripts and adjust
	+ particular attention to REP update logic


Note: by now, only terrestrial LOCEVALs were done.
```sql
loceval_staging=# SELECT DISTINCT activity_group_id FROM "inbound"."Visits" WHERE visit_done;
 activity_group_id 
-------------------
                18
(1 row)

SELECT DISTINCT activity_group_id, activity_group
FROM "metadata"."GroupedActivities"
WHERE activity_group_id IN (
SELECT DISTINCT activity_group_id FROM "inbound"."Visits"
WHERE archive_version_id IS NULL
)
ORDER BY activity_group_id
;

```

constraints:
```sql
\d+ "inbound"."Visits"
Indexes:
    "Visits_pkey" PRIMARY KEY, btree (visit_id)
Check constraints:
    "Visits_grts_address_check" CHECK (grts_address > 0)
Foreign-key constraints:
    "fk_fieldcalendars_visits" FOREIGN KEY (fieldcalendar_id) REFERENCES outbound."FieldCalendars"(fieldcalendar_id) ON UPDATE CASCADE ON DELETE SET NULL
    "fk_locations_visits" FOREIGN KEY (location_id) REFERENCES metadata."Locations"(location_id) ON UPDATE CASCADE ON DELETE SET NULL
    "fk_sampleunits_visits" FOREIGN KEY (sampleunit_id) REFERENCES outbound."SampleUnits"(sampleunit_id) ON UPDATE CASCADE ON DELETE SET NULL
    "fk_versions_visits" FOREIGN KEY (archive_version_id) REFERENCES metadata."Versions"(version_id) ON UPDATE CASCADE ON DELETE SET NULL

```

## deployment script
```sql
BEGIN;

-- free constraint names
ALTER SEQUENCE "inbound".seq_visit_id RENAME TO seq_preservedvisit_id;
ALTER TABLE "inbound"."Visits" RENAME CONSTRAINT  "Visits_pkey" TO "PreservedVisits_pkey";
ALTER TABLE "inbound"."Visits" RENAME CONSTRAINT  "Visits_grts_address_check" TO "PreservedVisits_grts_address_check";
ALTER TABLE "inbound"."Visits" RENAME CONSTRAINT  "fk_fieldcalendars_visits" TO "fk_fieldcalendars_preservedvisits";
ALTER TABLE "inbound"."Visits" RENAME CONSTRAINT  "fk_locations_visits" TO "fk_locations_preservedvisits";
ALTER TABLE "inbound"."Visits" RENAME CONSTRAINT  "fk_sampleunits_visits" TO "fk_sampleunits_preservedvisits";
ALTER TABLE "inbound"."Visits" RENAME CONSTRAINT  "fk_versions_visits"  TO "fk_versions_preservedvisits" ;
ALTER TABLE "inbound"."Visits" RENAME CONSTRAINT  "Visits_visit_id_not_null" TO "PreservedVisits_visit_id_not_null";
ALTER TABLE "inbound"."Visits" RENAME CONSTRAINT  "Visits_log_user_not_null" TO "PreservedVisits_log_user_not_null";
ALTER TABLE "inbound"."Visits" RENAME CONSTRAINT  "Visits_log_update_not_null" TO "PreservedVisits_log_update_not_null";
ALTER TABLE "inbound"."Visits" RENAME CONSTRAINT  "Visits_grts_address_not_null" TO "PreservedVisits_grts_address_not_null";
ALTER TABLE "inbound"."Visits" RENAME CONSTRAINT  "Visits_visit_done_not_null" TO "PreservedVisits_visit_done_not_null";
ALTER TABLE "inbound"."Visits" RENAME CONSTRAINT  "Visits_issues_not_null" TO "PreservedVisits_issues_not_null";


-- store existing data
ALTER TABLE "inbound"."Visits" RENAME TO "PreservedVisits";


DROP TABLE IF EXISTS "inbound"."Visits" CASCADE;
DROP TABLE IF EXISTS "inbound"."OtherVisits" CASCADE;
DROP TABLE IF EXISTS "inbound"."AquaticTypesVisits" CASCADE;
DROP TABLE IF EXISTS "inbound"."TerrestrialTypesVisits" CASCADE;

CREATE TABLE "inbound"."Visits"();
COMMENT ON TABLE "inbound"."Visits" IS E'inbound information about location visits, linked to SampleUnits and FieldCalendars';

ALTER TABLE "inbound"."Visits" ADD COLUMN visit_id int NOT NULL PRIMARY KEY;
COMMENT ON COLUMN "inbound"."Visits".visit_id IS E'visit index';
ALTER TABLE "inbound"."Visits" ADD COLUMN log_user varchar NOT NULL DEFAULT current_user;
COMMENT ON COLUMN "inbound"."Visits".log_user IS E'(technical) user who modified the entry';
ALTER TABLE "inbound"."Visits" ADD COLUMN log_update timestamp NOT NULL DEFAULT current_timestamp;
COMMENT ON COLUMN "inbound"."Visits".log_update IS E'(technical) timestamp of last modification';
ALTER TABLE "inbound"."Visits" ADD COLUMN fieldcalendar_id int;
COMMENT ON COLUMN "inbound"."Visits".fieldcalendar_id IS E'link to calendar index (technical)';
ALTER TABLE "inbound"."Visits" ADD COLUMN sampleunit_id int;
COMMENT ON COLUMN "inbound"."Visits".sampleunit_id IS E'sample location index (technical) or NULL for obsolete visits';
ALTER TABLE "inbound"."Visits" ADD COLUMN location_id int;
COMMENT ON COLUMN "inbound"."Visits".location_id IS E'the technical sequence of all locations, put here for quick join';
ALTER TABLE "inbound"."Visits" ADD COLUMN grts_address bigint NOT NULL CHECK (grts_address > 0);
COMMENT ON COLUMN "inbound"."Visits".grts_address IS E'GRTS address (`final`, i.e. after prior replacements) needed for retainer lookup';
ALTER TABLE "inbound"."Visits" ADD COLUMN type varchar NOT NULL;
COMMENT ON COLUMN "inbound"."Visits".type IS E'type, as planned in the sampling procedure';
ALTER TABLE "inbound"."Visits" ADD COLUMN activity_group_id smallint NOT NULL CHECK (activity_group_id > 0);
COMMENT ON COLUMN "inbound"."Visits".activity_group_id IS E'a link to the activity metadata';
ALTER TABLE "inbound"."Visits" ADD COLUMN date_start date NOT NULL;
COMMENT ON COLUMN "inbound"."Visits".date_start IS E'start of the panel activity sequence';
ALTER TABLE "inbound"."Visits" ADD COLUMN teammember_id smallint;
COMMENT ON COLUMN "inbound"."Visits".teammember_id IS E'link to the user who performed the visit';
ALTER TABLE "inbound"."Visits" ADD COLUMN date_visit date;
COMMENT ON COLUMN "inbound"."Visits".date_visit IS E'date of the field activity';
ALTER TABLE "inbound"."Visits" ADD COLUMN type_assessed varchar DEFAULT CAST('onveranderd' AS VARCHAR);
COMMENT ON COLUMN "inbound"."Visits".type_assessed IS E'referring to "N2kHabTypes"."type"; any corrections from previous evaluation';
ALTER TABLE "inbound"."Visits" ADD COLUMN is_well_developed_type boolean;
COMMENT ON COLUMN "inbound"."Visits".is_well_developed_type IS E'register cells which contain a well developed type, for info to adjacent teams/location research';
ALTER TABLE "inbound"."Visits" ADD COLUMN replacement_recovery_notes varchar;
COMMENT ON COLUMN "inbound"."Visits".replacement_recovery_notes IS E'extra recovery notes for local replacements';
ALTER TABLE "inbound"."Visits" ADD COLUMN gps_type varchar;
COMMENT ON COLUMN "inbound"."Visits".gps_type IS E'which type of GPS was used';
ALTER TABLE "inbound"."Visits" ADD COLUMN gps_accuracy_cm double precision;
COMMENT ON COLUMN "inbound"."Visits".gps_accuracy_cm IS E'measurement accuracy of the RTK GPS, expressed in centimeters';
ALTER TABLE "inbound"."Visits" ADD COLUMN notes text;
COMMENT ON COLUMN "inbound"."Visits".notes IS E'Free text notes from the previous visits';
ALTER TABLE "inbound"."Visits" ADD COLUMN photo varchar;
COMMENT ON COLUMN "inbound"."Visits".photo IS E'an optional photo of the site or noteworthy thing';
ALTER TABLE "inbound"."Visits" ADD COLUMN issues boolean NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN "inbound"."Visits".issues IS E'highlight issues (use notes to specify)';
ALTER TABLE "inbound"."Visits" ADD COLUMN visit_done boolean NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN "inbound"."Visits".visit_done IS E'filter column for locations which have already been visited';
ALTER TABLE "inbound"."Visits" ADD COLUMN archive_version_id smallint;
COMMENT ON COLUMN "inbound"."Visits".archive_version_id IS E'(technical) flag archived visits';


CREATE TABLE "inbound"."OtherVisits"()
INHERITS ("inbound"."Visits");
COMMENT ON TABLE "inbound"."OtherVisits" IS E'inbound information about field visits which are not otherwise specified';

ALTER TABLE "inbound"."OtherVisits" ADD COLUMN othervisit_id int NOT NULL PRIMARY KEY;
COMMENT ON COLUMN "inbound"."OtherVisits".othervisit_id IS E'visit index';



CREATE TABLE "inbound"."AquaticTypesVisits"()
INHERITS ("inbound"."Visits");
COMMENT ON TABLE "inbound"."AquaticTypesVisits" IS E'extra information collected for loceval of aquatic habitats; subset of Visits';

ALTER TABLE "inbound"."AquaticTypesVisits" ADD COLUMN aquatictypesvisit_id int NOT NULL PRIMARY KEY;
COMMENT ON COLUMN "inbound"."AquaticTypesVisits".aquatictypesvisit_id IS E'visit index';



CREATE TABLE "inbound"."TerrestrialTypesVisits"()
INHERITS ("inbound"."Visits");

COMMENT ON TABLE "inbound"."TerrestrialTypesVisits" IS E'extra information collected for loceval of terrestrial habitats; subset of Visits';
ALTER TABLE "inbound"."TerrestrialTypesVisits" ADD COLUMN terrestrialtypesvisit_id int NOT NULL PRIMARY KEY;
COMMENT ON COLUMN "inbound"."TerrestrialTypesVisits".terrestrialtypesvisit_id IS E'visit index';


-- sequence visit_id
CREATE SEQUENCE "inbound".seq_visit_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "inbound"."Visits".visit_id;
ALTER TABLE "inbound"."Visits" ALTER COLUMN visit_id
 SET DEFAULT nextval('inbound.seq_visit_id'::regclass);

GRANT USAGE ON SEQUENCE "inbound"."seq_visit_id" TO viewer_mnmdb;
GRANT SELECT ON SEQUENCE "inbound"."seq_visit_id" TO viewer_mnmdb;

ALTER TABLE "inbound"."Visits" DROP CONSTRAINT IF EXISTS fk_FieldCalendars_Visits CASCADE;
ALTER TABLE "inbound"."Visits" ADD CONSTRAINT fk_FieldCalendars_Visits FOREIGN KEY (fieldcalendar_id)
REFERENCES "outbound"."FieldCalendars" (fieldcalendar_id) MATCH SIMPLE
ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "inbound"."Visits" DROP CONSTRAINT IF EXISTS fk_SampleUnits_Visits CASCADE;
ALTER TABLE "inbound"."Visits" ADD CONSTRAINT fk_SampleUnits_Visits FOREIGN KEY (sampleunit_id)
REFERENCES "outbound"."SampleUnits" (sampleunit_id) MATCH SIMPLE
ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "inbound"."Visits" DROP CONSTRAINT IF EXISTS fk_Locations_Visits CASCADE;
ALTER TABLE "inbound"."Visits" ADD CONSTRAINT fk_Locations_Visits FOREIGN KEY (location_id)
REFERENCES "metadata"."Locations" (location_id) MATCH SIMPLE
ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "inbound"."Visits" DROP CONSTRAINT IF EXISTS fk_Versions_Visits CASCADE;
ALTER TABLE "inbound"."Visits" ADD CONSTRAINT fk_Versions_Visits FOREIGN KEY (archive_version_id)
REFERENCES "metadata"."Versions" (version_id) MATCH SIMPLE
ON DELETE SET NULL ON UPDATE CASCADE;

GRANT SELECT ON "inbound"."Visits" TO viewer_mnmdb;
GRANT INSERT ON "inbound"."Visits" TO user_loceval;
GRANT UPDATE ON "inbound"."Visits" TO user_loceval;
GRANT DELETE ON "inbound"."Visits" TO user_loceval;



CREATE SEQUENCE "inbound".seq_othervisit_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "inbound"."OtherVisits".othervisit_id;
ALTER TABLE "inbound"."OtherVisits" ALTER COLUMN othervisit_id
 SET DEFAULT nextval('inbound.seq_othervisit_id'::regclass);

GRANT USAGE ON SEQUENCE "inbound"."seq_othervisit_id" TO viewer_mnmdb;
GRANT SELECT ON SEQUENCE "inbound"."seq_othervisit_id" TO viewer_mnmdb;
GRANT SELECT ON "inbound"."OtherVisits" TO viewer_mnmdb;
GRANT INSERT ON "inbound"."OtherVisits" TO user_loceval;
GRANT UPDATE ON "inbound"."OtherVisits" TO user_loceval;
GRANT DELETE ON "inbound"."OtherVisits" TO user_loceval;


CREATE SEQUENCE "inbound".seq_aquatictypesvisit_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "inbound"."AquaticTypesVisits".aquatictypesvisit_id;
ALTER TABLE "inbound"."AquaticTypesVisits" ALTER COLUMN aquatictypesvisit_id
 SET DEFAULT nextval('inbound.seq_aquatictypesvisit_id'::regclass);

GRANT USAGE ON SEQUENCE "inbound"."seq_aquatictypesvisit_id" TO viewer_mnmdb;
GRANT SELECT ON SEQUENCE "inbound"."seq_aquatictypesvisit_id" TO viewer_mnmdb;
GRANT SELECT ON "inbound"."AquaticTypesVisits" TO viewer_mnmdb;
GRANT INSERT ON "inbound"."AquaticTypesVisits" TO user_loceval;
GRANT UPDATE ON "inbound"."AquaticTypesVisits" TO user_loceval;
GRANT DELETE ON "inbound"."AquaticTypesVisits" TO user_loceval;


CREATE SEQUENCE "inbound".seq_terrestrialtypesvisit_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "inbound"."TerrestrialTypesVisits".terrestrialtypesvisit_id;
ALTER TABLE "inbound"."TerrestrialTypesVisits" ALTER COLUMN terrestrialtypesvisit_id
 SET DEFAULT nextval('inbound.seq_terrestrialtypesvisit_id'::regclass);

GRANT USAGE ON SEQUENCE "inbound"."seq_terrestrialtypesvisit_id" TO viewer_mnmdb;
GRANT SELECT ON SEQUENCE "inbound"."seq_terrestrialtypesvisit_id" TO viewer_mnmdb;
GRANT SELECT ON "inbound"."TerrestrialTypesVisits" TO viewer_mnmdb;
GRANT INSERT ON "inbound"."TerrestrialTypesVisits" TO user_loceval;
GRANT UPDATE ON "inbound"."TerrestrialTypesVisits" TO user_loceval;
GRANT DELETE ON "inbound"."TerrestrialTypesVisits" TO user_loceval;


COMMIT;

```

re-distributing data:
```sql
INSERT INTO "inbound"."TerrestrialTypesVisits" (
  log_user,log_update,
  fieldcalendar_id,sampleunit_id,location_id,
  grts_address,type,activity_group_id,date_start,
  teammember_id,date_visit,type_assessed,is_well_developed_type,
  replacement_recovery_notes,gps_type,gps_accuracy_cm,notes,
  photo,issues,visit_done,
  archive_version_id
)
SELECT
  log_user,log_update,
  fieldcalendar_id,sampleunit_id,location_id,
  grts_address,type,activity_group_id,date_start,
  teammember_id,date_visit,type_assessed,is_well_developed_type,
  replacement_recovery_notes,gps_type,gps_accuracy_cm,notes,
  photo,issues,visit_done,
  archive_version_id
FROM "inbound"."PreservedVisits"
WHERE activity_group_id = 18
;


INSERT INTO "inbound"."AquaticTypesVisits" (
  log_user,log_update,
  fieldcalendar_id,sampleunit_id,location_id,
  grts_address,type,activity_group_id,date_start,
  teammember_id,date_visit,type_assessed,is_well_developed_type,
  replacement_recovery_notes,gps_type,gps_accuracy_cm,notes,
  photo,issues,visit_done,
  archive_version_id
)
SELECT
  log_user,log_update,
  fieldcalendar_id,sampleunit_id,location_id,
  grts_address,type,activity_group_id,date_start,
  teammember_id,date_visit,type_assessed,is_well_developed_type,
  replacement_recovery_notes,gps_type,gps_accuracy_cm,notes,
  photo,issues,visit_done,
  archive_version_id
FROM "inbound"."PreservedVisits"
WHERE activity_group_id = 17
;


INSERT INTO "inbound"."OtherVisits" (
  log_user,log_update,
  fieldcalendar_id,sampleunit_id,location_id,
  grts_address,type,activity_group_id,date_start,
  teammember_id,date_visit,type_assessed,is_well_developed_type,
  replacement_recovery_notes,gps_type,gps_accuracy_cm,notes,
  photo,issues,visit_done,
  archive_version_id
)
SELECT
  log_user,log_update,
  fieldcalendar_id,sampleunit_id,location_id,
  grts_address,type,activity_group_id,date_start,
  teammember_id,date_visit,type_assessed,is_well_developed_type,
  replacement_recovery_notes,gps_type,gps_accuracy_cm,notes,
  photo,issues,visit_done,
  archive_version_id
FROM "inbound"."PreservedVisits"
WHERE activity_group_id NOT IN (17, 18)
;



-- check
SELECT * FROM (
  SELECT DISTINCT
   PV.grts_address, PV.type, PV.activity_group_id, PV.date_start, V.visit_id
  FROM "inbound"."PreservedVisits" AS PV
  LEFT JOIN "inbound"."Visits" AS V
  ON (
      PV.grts_address = V.grts_address
  AND PV.type = V.type
  AND PV.activity_group_id = V.activity_group_id
  AND PV.date_start = V.date_start
  )
) AS VIS
WHERE VIS.visit_id IS NULL
;

```

Finally, restore updated Views (were cascade-deleted or link to wrong table)
- `loceval_LocevalFieldwork.sql`
- `loceval_LocationEvaluation_old.sql`
- `loceval_gwTransfer.sql`
- `loceval_ReplacementOngoing.sql`

Tested in QGIS, seems all fine.