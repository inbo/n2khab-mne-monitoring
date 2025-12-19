
COMMENT ON TABLE "metadata"."Protocols" IS E'protocols, linked to protocols.inbo.be';

ALTER TABLE "metadata"."Protocols"
RENAME COLUMN protocol TO protocol_code;
COMMENT ON COLUMN "metadata"."Protocols".protocol_code IS E'protocol short label';

ALTER TABLE "metadata"."Protocols" ADD COLUMN protocol_version varchar;
COMMENT ON COLUMN "metadata"."Protocols".protocol_version IS E'protocol version';

ALTER TABLE "metadata"."Protocols" ADD COLUMN title varchar;
COMMENT ON COLUMN "metadata"."Protocols".title IS E'descriptive title of the protocol';

ALTER TABLE "metadata"."Protocols" ADD COLUMN subtitle varchar;
COMMENT ON COLUMN "metadata"."Protocols".subtitle IS E'optional subtitle';

ALTER TABLE "metadata"."Protocols" ADD COLUMN language varchar;
COMMENT ON COLUMN "metadata"."Protocols".language IS E'Dutch, usually';

ALTER TABLE "metadata"."Protocols" ADD COLUMN theme varchar;
COMMENT ON COLUMN "metadata"."Protocols".theme IS E'category/topic of the protocol (optional, but useful)';

ALTER TABLE "metadata"."Protocols" ADD COLUMN manager varchar;
COMMENT ON COLUMN "metadata"."Protocols".manager IS E'the person to contact for questions';

ALTER TABLE "metadata"."Protocols" DROP COLUMN description;


ALTER TABLE "metadata"."Protocols" ADD CONSTRAINT uq_protocol UNIQUE (protocol_code, protocol_version);


-- upload with POC update
./loceval_dev_structure/data_Protocols.csv

- [X] remove ",..." in vivo and in POC
- [X] tolower in vivo


-- change existing version and protocol code

-- https://docs.google.com/spreadsheets/d/1gJb2nY-Cs-SCNMpz0sGFslb0j69mzNx5BJu9tQXpHfc/edit?gid=1617790174#gid=1617790174
UPDATE "metadata"."Protocols"
SET protocol_code = 'spp-002-nl', protocol_version = '2025.-2'
WHERE protocol_code = 'sfp-001-nl, ...';
UPDATE "metadata"."Protocols"
SET protocol_code = 'sfp-403-nl', protocol_version = '2023.05'
WHERE protocol_code = 'sfp-403-nl, ...';
UPDATE "metadata"."Protocols"
SET protocol_code = 'sfp-105-nl', protocol_version = '2023.09'
WHERE protocol_code = 'sfp-105-nl';
UPDATE "metadata"."Protocols"
SET protocol_code = 'sfp-201-nl', protocol_version = '2024.01'
WHERE protocol_code = 'sfp-201-nl';
UPDATE "metadata"."Protocols"
SET protocol_code = 'spp-003-nl', protocol_version = '2025.-1'
WHERE protocol_code = 'sfp-104-nl';
UPDATE "metadata"."Protocols"
SET protocol_code = 'spp-116-nl', protocol_version = '2024.05'
WHERE protocol_code = 'spp-116-nl';
UPDATE "metadata"."Protocols"
SET protocol_code = 'spp-117-nl', protocol_version = '2024.06'
WHERE protocol_code = 'spp-117-nl';


-- codes which do not exist
DELETE FROM "metadata"."Protocols"
WHERE protocol_code = 'SVP-014';
DELETE FROM "metadata"."Protocols"
WHERE protocol_code = 'SVP-110';
DELETE FROM "metadata"."Protocols"
WHERE protocol_code = 'SVP-119';
DELETE FROM "metadata"."Protocols"
WHERE protocol_code = 'sfp-116-nl';
DELETE FROM "metadata"."Protocols"
WHERE protocol_code = 'sfp-117-nl';


-- add constraint
ALTER TABLE "metadata"."Protocols" ALTER COLUMN protocol_version SET NOT NULL;

-- update view
!!! update FieldWork view of mnmgwdb

-- create the metadata.Versions table

-- !!! TODO:
-- link GroupedActivities (by activity / group code)
