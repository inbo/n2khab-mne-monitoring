#!/usr/bin/env python3

import MNMDatabaseToolbox as DTB

# https://docs.google.com/spreadsheets/d/12dWpyS2Wsjog3-z3q6-pUzlAnY4MuBbh6igDWH9bEZw/edit?usp=drive_link
# SET search_path TO public,"metadata","outbound","inbound";


if True:
    # database: loceval_dev
    base_folder = DTB.PL.Path(".")
    structure_folder = base_folder/"mnmfield_dev_structure"
    DTB.ODStoCSVs(base_folder/"mnmfield_dev_dbstructure.ods", structure_folder)

    db_connection = DTB.ConnectDatabase(
        "inbopostgis_server.conf",
        connection_config = "mnmfield-dev",
        database = "mnmfield_dev"
        )
    db = DTB.Database( \
        structure_folder = structure_folder, \
        definition_csv = "TABLES.csv", \
        lazy_creation = False, \
        db_connection = db_connection, \
        tabula_rasa = False
        )


if False:
    #### TODO prompt accidental overwrite

    # database: loceval
    base_folder = DTB.PL.Path(".")
    structure_folder = base_folder/"mnmfield_db_structure"
    DTB.ODStoCSVs(base_folder/"mnmfield_dbstructure.ods", structure_folder)

    db_connection = DTB.ConnectDatabase(
        "inbopostgis_server.conf",
        connection_config = "mnmfield",
        database = "loceval"
    )
    db = DTB.Database( \
        structure_folder = structure_folder, \
        definition_csv = "TABLES.csv", \
        lazy_creation = False, \
        db_connection = db_connection, \
        tabula_rasa = False
    )

