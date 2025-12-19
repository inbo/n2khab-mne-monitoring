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

GRANT USAGE ON SEQUENCE "inbound"."seq_fieldwork_id" TO tom;
GRANT USAGE ON SEQUENCE "inbound"."seq_fieldwork_id" TO yglinga;
GRANT USAGE ON SEQUENCE "inbound"."seq_fieldwork_id" TO jens;
GRANT USAGE ON SEQUENCE "inbound"."seq_fieldwork_id" TO lise;
GRANT USAGE ON SEQUENCE "inbound"."seq_fieldwork_id" TO wouter;
GRANT USAGE ON SEQUENCE "inbound"."seq_fieldwork_id" TO floris;
GRANT USAGE ON SEQUENCE "inbound"."seq_fieldwork_id" TO karen;
GRANT USAGE ON SEQUENCE "inbound"."seq_fieldwork_id" TO ward;
GRANT SELECT ON SEQUENCE "inbound"."seq_fieldwork_id" TO monkey;

GRANT USAGE ON SEQUENCE "inbound"."seq_fieldwork_id" TO tom, ward;
