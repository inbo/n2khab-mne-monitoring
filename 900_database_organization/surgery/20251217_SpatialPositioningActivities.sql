SET standard_conforming_strings = ON;
-- SET search_path TO pg_catalog,public,"inbound";

DROP TABLE IF EXISTS "inbound"."SpatialPositioningActivities" CASCADE;

BEGIN;
CREATE TABLE "inbound"."SpatialPositioningActivities"();

COMMENT ON TABLE "inbound"."SpatialPositioningActivities" IS E'information collected for certain activities (spatial positioning); linked to a subset of Visits';

ALTER TABLE "inbound"."SpatialPositioningActivities" ADD COLUMN fieldwork_id int NOT NULL PRIMARY KEY;
COMMENT ON COLUMN "inbound"."SpatialPositioningActivities".fieldwork_id IS E'fieldwork index: shared index over multiple fieldwork activity tables';

ALTER TABLE "inbound"."SpatialPositioningActivities" ADD COLUMN log_user varchar NOT NULL DEFAULT current_user;
COMMENT ON COLUMN "inbound"."SpatialPositioningActivities".log_user IS E'(technical) user who modified the entry';

ALTER TABLE "inbound"."SpatialPositioningActivities" ADD COLUMN log_update timestamp NOT NULL DEFAULT current_timestamp;
COMMENT ON COLUMN "inbound"."SpatialPositioningActivities".log_update IS E'(technical) timestamp of last modification';

ALTER TABLE "inbound"."SpatialPositioningActivities" ADD COLUMN samplelocation_id int;
COMMENT ON COLUMN "inbound"."SpatialPositioningActivities".samplelocation_id IS E'sample location index (technical) or NULL for obsolete visits';

ALTER TABLE "inbound"."SpatialPositioningActivities" ADD COLUMN fieldworkcalendar_id int;
COMMENT ON COLUMN "inbound"."SpatialPositioningActivities".fieldworkcalendar_id IS E'link to FwC';

ALTER TABLE "inbound"."SpatialPositioningActivities" ADD COLUMN visit_id int;
COMMENT ON COLUMN "inbound"."SpatialPositioningActivities".visit_id IS E'link to the `Visits`';

ALTER TABLE "inbound"."SpatialPositioningActivities" ADD COLUMN grts_address bigint NOT NULL CHECK (grts_address > 0);
COMMENT ON COLUMN "inbound"."SpatialPositioningActivities".grts_address IS E'GRTS address (`final`, i.e. after prior replacements) needed for retainer lookup';

ALTER TABLE "inbound"."SpatialPositioningActivities" ADD COLUMN stratum varchar NOT NULL;
COMMENT ON COLUMN "inbound"."SpatialPositioningActivities".stratum IS E'strata for which the cell is eligible';

ALTER TABLE "inbound"."SpatialPositioningActivities" ADD COLUMN activity_group_id smallint NOT NULL;
COMMENT ON COLUMN "inbound"."SpatialPositioningActivities".activity_group_id IS E'a link to the activity metadata, brought here via fieldworkcalendar for convenience';

ALTER TABLE "inbound"."SpatialPositioningActivities" ADD COLUMN date_start date NOT NULL;
COMMENT ON COLUMN "inbound"."SpatialPositioningActivities".date_start IS E'start of the panel activity sequence (included to keep recurrent visits unique)';

ALTER TABLE "inbound"."SpatialPositioningActivities" ADD COLUMN require_total_station boolean;
COMMENT ON COLUMN "inbound"."SpatialPositioningActivities".require_total_station IS E'whether or not total station will be / was required for sattelite connection upon positioning';

COMMIT;

-- foreign key fieldworkcalendar_id
ALTER TABLE "inbound"."SpatialPositioningActivities" DROP CONSTRAINT IF EXISTS fk_FieldworkCalendar_SpatialPositioningActivities CASCADE;
ALTER TABLE "inbound"."SpatialPositioningActivities" ADD CONSTRAINT fk_FieldworkCalendar_SpatialPositioningActivities FOREIGN KEY (fieldworkcalendar_id)
REFERENCES "outbound"."FieldworkCalendar" (fieldworkcalendar_id) MATCH SIMPLE
ON DELETE SET NULL ON UPDATE CASCADE;

-- foreign key visit_id
ALTER TABLE "inbound"."SpatialPositioningActivities" DROP CONSTRAINT IF EXISTS fk_Visits_SpatialPositioningActivities CASCADE;
ALTER TABLE "inbound"."SpatialPositioningActivities" ADD CONSTRAINT fk_Visits_SpatialPositioningActivities FOREIGN KEY (visit_id)
REFERENCES "inbound"."Visits" (visit_id) MATCH SIMPLE
ON DELETE SET NULL ON UPDATE CASCADE;

GRANT SELECT ON "inbound"."SpatialPositioningActivities" TO tom, yglinga, jens, lise, wouter, floris, karen, falk, ward, monkey;
GRANT INSERT ON "inbound"."SpatialPositioningActivities" TO tom;
GRANT UPDATE ON "inbound"."SpatialPositioningActivities" TO tom, yglinga, jens, lise, wouter, floris, karen, falk, ward;
GRANT DELETE ON "inbound"."SpatialPositioningActivities" TO tom;



-- re-create views:  "inbound"."FieldWork", "inbound"."MyFieldWork" ;

-- adjusted 070_update_POC.qmd
-- adjusted 092_update_facalendar.R but it crashed on re-working
-- adjusted 040m_mnmgwdb_consistency_dashboard.qmd
-- adjusted 095_reset_fieldwork_id.R, of course; SPA gets +20000
