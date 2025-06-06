#!/usr/bin/env python3

import GenerateDatabase as GDB

# https://docs.google.com/spreadsheets/d/12dWpyS2Wsjog3-z3q6-pUzlAnY4MuBbh6igDWH9bEZw/edit?usp=drive_link
# database: loceval
base_folder = GDB.PL.Path(".")
GDB.ODStoCSVs(base_folder/"loceval_outbound.ods", base_folder/"db_structure")

db_connection = GDB.ConnectDatabase("inbopostgis_server.conf")
db = GDB.Database( \
    base_folder = "./db_structure", \
    definition_csv = "TABLES.csv", \
    lazy_creation = False, \
    db_connection = db_connection \
)

# SET search_path TO public,"loceval_outbound";

