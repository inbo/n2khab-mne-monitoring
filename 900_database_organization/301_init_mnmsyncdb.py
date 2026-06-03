#!/usr/bin/env python3

import MNMDatabaseToolbox as DTB

# SET search_path TO public,"metadata","outbound","inbound";

restore_dev = True
restore_staging = False
restore_testing = False # tabula rasa; note that it requires `dev` roles but works on `prod` structure

base_folder = DTB.PL.Path(".")
DTB.ODStoCSVs(base_folder/"mnmsyncdb_dev_structure.ods", base_folder/"mnmsyncdb_dev_structure")
DTB.ODStoCSVs(base_folder/"mnmsyncdb_db_structure.ods", base_folder/"mnmsyncdb_db_structure")

### (1) development
# the dev database mirror is used for structural adjustments and development of
# new features, mostly empty, and unstable.

if restore_dev:
    # database: mnmsyncdb_dev
    db_connection = DTB.ConnectDatabase(
        base_folder/"mnm_database_connection.conf",
        connection_config = "mnmsyncdb-dev",
        )
    db = DTB.Database( \
        structure_folder = base_folder/"mnmsyncdb_dev_structure", \
        definition_csv = "TABLES.csv", \
        lazy_creation = False, \
        db_connection = db_connection, \
        tabula_rasa = False
        )


### (2) staging
# "staging" is a rather accurate mirror of the production database,
# but used ad hoc in times of change to back-up the data or to test the effects
# of structural adjustments.

if restore_staging:
    # database: mnmsyncdb_dev
    db_connection = DTB.ConnectDatabase(
        base_folder/"mnm_database_connection.conf",
        connection_config = "mnmsyncdb-staging",
        )
    db = DTB.Database( \
        structure_folder = base_folder/"mnmsyncdb_db_structure", \
        definition_csv = "TABLES.csv", \
        lazy_creation = False, \
        db_connection = db_connection, \
        tabula_rasa = True
        )



### (3) testing
# The testing mirror is an exact copy of the production database, and
# regularly re-copied over. Changes to the data on "testing" are non-permanent.

if restore_testing:
    # database: mnmsyncdb_dev
    db_connection = DTB.ConnectDatabase(
        base_folder/"mnm_database_connection.conf",
        connection_config = "mnmsyncdb-testing",
        )
    db = DTB.Database( \
        structure_folder = base_folder/"mnmsyncdb_dev_structure", \
        definition_csv = "TABLES.csv", \
        lazy_creation = False, \
        db_connection = db_connection, \
        tabula_rasa = True
        )



### (4) production
# This is the live environment with real data.
# It is the least volatile, best backed-up of our database mirrors.

if False:
    #### TODO prompt accidental overwrite

    # database: mnmsyncdb PRODUCTION
    db_connection = DTB.ConnectDatabase(
        base_folder/"mnm_database_connection.conf",
        connection_config = "mnmsyncdb",
    )
    db = DTB.Database( \
        structure_folder = base_folder/"mnmsyncdb_db_structure", \
        definition_csv = "TABLES.csv", \
        lazy_creation = False, \
        db_connection = db_connection, \
        tabula_rasa = False
    )
