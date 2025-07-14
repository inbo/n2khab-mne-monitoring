SET search_path TO public,"metadata","outbound","inbound","archive","analysis";

GRANT USAGE ON SCHEMA "metadata" TO tester;
GRANT USAGE ON SCHEMA "outbound" TO tester;
GRANT USAGE ON SCHEMA "inbound" TO tester;
GRANT USAGE ON SCHEMA "archive" TO tester;
GRANT SELECT ON ALL TABLES IN SCHEMA "metadata" TO tester;
GRANT SELECT ON ALL TABLES IN SCHEMA "inbound" TO tester;
GRANT SELECT ON ALL TABLES IN SCHEMA "outbound" TO tester;
GRANT UPDATE ON ALL TABLES IN SCHEMA "inbound" TO tester;
GRANT UPDATE ON ALL TABLES IN SCHEMA "outbound" TO tester;
GRANT DELETE ON ALL TABLES IN SCHEMA "inbound" TO tester;
