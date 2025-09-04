
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

- [ ] remove ",..." in vivo and in POC
- [ ] tolower in vivo

-- !!! TODO:
ALTER TABLE "metadata"."Protocols" ALTER COLUMN protocol_version SET NOT NULL;
