#!/usr/bin/env python3

import MNMDatabaseToolbox as DTB

# https://docs.google.com/spreadsheets/d/12dWpyS2Wsjog3-z3q6-pUzlAnY4MuBbh6igDWH9bEZw/edit?usp=drive_link
# SET search_path TO public,"metadata","outbound","inbound","archive";

restore_dev = False
restore_staging = False
restore_testing = True # tabula rasa; note that it requires `dev` roles but works on `prod` structure

base_folder = DTB.PL.Path(".")
DTB.ODStoCSVs(base_folder/"loceval_dev_structure.ods", base_folder/"loceval_dev_structure")
DTB.ODStoCSVs(base_folder/"loceval_db_structure.ods", base_folder/"loceval_db_structure")

### (1) development
# the dev database mirror is used for structural adjustments and development of
# new features, mostly empty, and unstable.

if restore_dev:
    # database: loceval_dev

    db_connection = DTB.ConnectDatabase(
        base_folder/"inbopostgis_server.conf",
        connection_config = "loceval-dev",
        )
    db = DTB.Database( \
        structure_folder = base_folder/"loceval_db_structure", \
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
    # database: loceval_staging

    db_connection = DTB.ConnectDatabase(
        base_folder/"inbopostgis_server.conf",
        connection_config = "loceval-staging",
        )
    db = DTB.Database( \
        structure_folder = base_folder/"loceval_db_structure", \
        lazy_creation = False, \
        db_connection = db_connection, \
        tabula_rasa = True
        )


### (3) testing
# The testing mirror is an exact copy of the production database, and
# regularly re-copied over. Changes to the data on "testing" are non-permanent.

if restore_testing:
    # database: loceval_testing
    # structure_folder = base_folder/"loceval_db_structure"
    # DTB.ODStoCSVs(base_folder/"loceval_dev_dbstructure.ods", structure_folder)

    db_connection = DTB.ConnectDatabase(
        base_folder/"inbopostgis_server.conf",
        connection_config = "loceval-testing",
        )
    db = DTB.Database( \
        structure_folder = base_folder/"loceval_dev_structure", \
        lazy_creation = False, \
        db_connection = db_connection, \
        tabula_rasa = True
        )


### (4) production
# This is the live environment with real data.
# It is the least volatile, best backed-up of our database mirrors.

if False:
    #### TODO prompt accidental overwrite

    # database: loceval
    db_connection = DTB.ConnectDatabase(
        base_folder/"inbopostgis_server.conf",
        connection_config = "loceval",
    )
    db = DTB.Database( \
        structure_folder = base_folder/"loceval_db_structure", \
        definition_csv = "TABLES.csv", \
        lazy_creation = False, \
        db_connection = db_connection, \
        tabula_rasa = False
    )

