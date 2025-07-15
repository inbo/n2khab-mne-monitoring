#!/usr/bin/env python3

import MNMDatabaseToolbox as DTB

# https://docs.google.com/spreadsheets/d/12dWpyS2Wsjog3-z3q6-pUzlAnY4MuBbh6igDWH9bEZw/edit?usp=drive_link
# SET search_path TO public,"metadata","outbound","inbound";


### (1) development
# the dev database mirror is used for structural adjustments and development of
# new features, mostly empty, and unstable.

if True:
    # database: mnmgwdb_dev
    base_folder = DTB.PL.Path(".")
    structure_folder = base_folder/"mnmgwdb_dev_structure"
    DTB.ODStoCSVs(base_folder/"mnmgwdb_dev_structure.ods", structure_folder)

    db_connection = DTB.ConnectDatabase(
        "inbopostgis_server.conf",
        connection_config = "mnmgwdb-dev",
        database = "mnmgwdb_dev"
        )
    db = DTB.Database( \
        structure_folder = structure_folder, \
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

    # database: mnmgwdb
    base_folder = DTB.PL.Path(".")
    structure_folder = base_folder/"mnmgwdb_db_structure"
    DTB.ODStoCSVs(base_folder/"mnmgwdb_db_structure.ods", structure_folder)

    db_connection = DTB.ConnectDatabase(
        "inbopostgis_server.conf",
        connection_config = "mnmgwdb",
        database = "mnmgwdb"
    )
    db = DTB.Database( \
        structure_folder = structure_folder, \
        definition_csv = "TABLES.csv", \
        lazy_creation = False, \
        db_connection = db_connection, \
        tabula_rasa = False
    )
