CREATE SEQUENCE "inbound".seq_fieldwork_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
;
ALTER TABLE "inbound"."WellInstallationActivities" ALTER COLUMN fieldwork_id
 SET DEFAULT nextval('inbound.seq_fieldwork_id'::regclass);

GRANT USAGE ON SEQUENCE "inbound"."seq_fieldwork_id" TO tom, yglinga, jens, lise, wouter, floris, karen, janne, ward;
GRANT SELECT ON SEQUENCE "inbound"."seq_fieldwork_id" TO monkey;

GRANT USAGE ON SEQUENCE "inbound"."seq_fieldwork_id" TO tom, ward;
