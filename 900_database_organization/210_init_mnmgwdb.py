#!/usr/bin/env python3

import MNMDatabaseToolbox as DTB

# https://docs.google.com/spreadsheets/d/12dWpyS2Wsjog3-z3q6-pUzlAnY4MuBbh6igDWH9bEZw/edit?usp=drive_link
# SET search_path TO public,"metadata","outbound","inbound";

restore_dev = False
# restore_staging = False
restore_testing = True # tabula rasa; note that it requires `dev` roles but works on `prod` structure

base_folder = DTB.PL.Path(".")
DTB.ODStoCSVs(base_folder/"mnmgwdb_dev_structure.ods", base_folder/"mnmgwdb_dev_structure")
DTB.ODStoCSVs(base_folder/"mnmgwdb_db_structure.ods", base_folder/"mnmgwdb_db_structure")

### (1) development
# the dev database mirror is used for structural adjustments and development of
# new features, mostly empty, and unstable.

if restore_dev:
    # database: mnmgwdb_dev
    db_connection = DTB.ConnectDatabase(
        base_folder/"inbopostgis_server.conf",
        connection_config = "mnmgwdb-dev",
        )
    db = DTB.Database( \
        structure_folder = base_folder/"mnmgwdb_dev_structure", \
        definition_csv = "TABLES.csv", \
        lazy_creation = False, \
        db_connection = db_connection, \
        tabula_rasa = False
        )


### (3) testing
# The testing mirror is an exact copy of the production database, and
# regularly re-copied over. Changes to the data on "testing" are non-permanent.

if restore_testing:
    # database: mnmgwdb_dev
    db_connection = DTB.ConnectDatabase(
        base_folder/"inbopostgis_server.conf",
        connection_config = "mnmgwdb-testing",
        )
    db = DTB.Database( \
        structure_folder = base_folder/"mnmgwdb_dev_structure", \
        definition_csv = "TABLES.csv", \
        lazy_creation = False, \
        db_connection = db_connection, \
        tabula_rasa = False
        )



### (4) production
# This is the live environment with real data.
# It is the least volatile, best backed-up of our database mirrors.

if False:
    #### TODO prompt accidental overwrite

    # database: mnmgwdb PRODUCTION
    db_connection = DTB.ConnectDatabase(
        base_folder/"inbopostgis_server.conf",
        connection_config = "mnmgwdb",
    )
    db = DTB.Database( \
        structure_folder = base_folder/"mnmgwdb_db_structure", \
        definition_csv = "TABLES.csv", \
        lazy_creation = False, \
        db_connection = db_connection, \
        tabula_rasa = False
    )
