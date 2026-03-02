-- ### delete and restore mnmgwdb_staging
-- [postgres@server ~]$ dropdb mnmgwdb_staging --port <port>
-- [postgres@server ~]$ createdb mnmgwdb_staging -O <me> --port <port>
-- [postgres@server ~]$ psql -d mnmgwdb_staging --port <port>
-- mnmgwdb_staging=# CREATE EXTENSION postgis;
--                   CREATE EXTENSION postgis_topology;
--                   CREATE EXTENSION fuzzystrmatch;
--                   CREATE EXTENSION postgis_tiger_geocoder;

-- ### restore loceval
-- can simply be a copy of the production db
--
-- pg_dump -U monkey -h <host> -p <port> -d loceval -N tiger -N public -c > /tmp/loceval_db_dump.txt \
--         && psql -U <user> -h <host> -p <port> -d loceval_staging -W < /tmp/loceval_db_dump.txt \
--         && rm /tmp/loceval_db_dump.txt

-- ### restore mnmgwdb
-- run "210*.py" to restore mnmgwdb staging -> creating schema's etc.

-- restore nightly backup
-- psql -U <user> -h <host> -p <port> -d mnmgwdb_staging -W < /data/git/n2khab-mne-monitoring_dbinit/900_database_organization/dumps/_20250818_mnmgwdb_pre_lost_replacement.sql
-- this one will throw errors (missed `-c`), but the data is good.

-- ### run script line by line


-- -> encountered and fixed multiple bugs.
--    - distinction between "grts_replaced" already exists and "grts_original" already existed (`to_duplicate`)
--    - re-inclusion of single replacements for duplication
--    - 'fieldwork_id' from UNION insead of view
