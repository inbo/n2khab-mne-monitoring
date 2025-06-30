#!/usr/bin/env python3

import MNMDatabaseToolbox as DTB

# https://docs.google.com/spreadsheets/d/12dWpyS2Wsjog3-z3q6-pUzlAnY4MuBbh6igDWH9bEZw/edit?usp=drive_link
# SET search_path TO public,"metadata","outbound","inbound";


if False:
    # database: loceval_dev
    base_folder = DTB.PL.Path(".")
    structure_folder = base_folder/"devdb_structure"
    DTB.ODStoCSVs(base_folder/"loceval_dev_dbstructure.ods", structure_folder)

    db_connection = DTB.ConnectDatabase(
        "inbopostgis_server.conf",
        connection_config = "inbopostgis-dev",
        database = "loceval_dev"
        )
    db = DTB.Database( \
        structure_folder = structure_folder, \
        definition_csv = "TABLES.csv", \
        lazy_creation = False, \
        db_connection = db_connection, \
        tabula_rasa = False
        )



if False:
    # database: loceval_testing
    base_folder = DTB.PL.Path(".")
    structure_folder = base_folder/"devdb_structure"
    DTB.ODStoCSVs(base_folder/"loceval_dev_dbstructure.ods", structure_folder)

    db_connection = DTB.ConnectDatabase(
        "inbopostgis_server.conf",
        connection_config = "testing",
        database = "loceval_testing"
        )
    db = DTB.Database( \
        structure_folder = structure_folder, \
        definition_csv = "TABLES.csv", \
        lazy_creation = False, \
        db_connection = db_connection, \
        tabula_rasa = True
        )



if True:
    #### TODO prompt accidental overwrite

    # database: loceval
    base_folder = DTB.PL.Path(".")
    structure_folder = base_folder/"db_structure"
    DTB.ODStoCSVs(base_folder/"loceval_dbstructure.ods", structure_folder)

    db_connection = DTB.ConnectDatabase(
        "inbopostgis_server.conf",
        connection_config = "inbopostgis",
        database = "loceval"
    )
    db = DTB.Database( \
        structure_folder = structure_folder, \
        definition_csv = "TABLES.csv", \
        lazy_creation = False, \
        db_connection = db_connection \
        , tabula_rasa = False
    )

