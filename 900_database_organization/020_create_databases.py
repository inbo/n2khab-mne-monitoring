#!/usr/bin/env python3

import MNMDatabaseToolbox as DTB


if True:
    # https://docs.google.com/spreadsheets/d/12dWpyS2Wsjog3-z3q6-pUzlAnY4MuBbh6igDWH9bEZw/edit?usp=drive_link
    # database: loceval
    base_folder = DTB.PL.Path(".")
    DTB.ODStoCSVs(base_folder/"loceval_dev_dbstructure.ods", base_folder/"devdb_structure")

    db_connection = DTB.ConnectDatabase(
        "inbopostgis_server.conf",
        connection_config = "inbopostgis-dev",
        database = "loceval_dev"
        )
    db = DTB.Database( \
        base_folder = "./devdb_structure", \
        definition_csv = "TABLES.csv", \
        lazy_creation = False, \
        db_connection = db_connection, \
        tabula_rasa = False
        )

    # SET search_path TO public,"metadata","outbound","inbound";


if False:
    #### TODO prompt accidental overwrite

    # https://docs.google.com/spreadsheets/d/12dWpyS2Wsjog3-z3q6-pUzlAnY4MuBbh6igDWH9bEZw/edit?usp=drive_link
    # database: loceval
    base_folder = DTB.PL.Path(".")
    DTB.ODStoCSVs(base_folder/"loceval_dbstructure.ods", base_folder/"db_structure")

    db_connection = DTB.ConnectDatabase(
        "inbopostgis_server.conf",
        connection_config = "inbopostgis",
        database = "loceval"
    )
    db = DTB.Database( \
        base_folder = "./db_structure", \
        definition_csv = "TABLES.csv", \
        lazy_creation = False, \
        db_connection = db_connection \
    )

# SET search_path TO public,"metadata","outbound","inbound";
