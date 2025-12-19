# DO NOT MODIFY
# this file is "tangled" automatically from `030_copy_database.org`.

import MNMDatabaseToolbox as DTB

# database:
base_folder = DTB.PL.Path(".")
structure_folder = base_folder/"loceval_db_structure"
DTB.ODStoCSVs(base_folder/"loceval_db_structure.ods", structure_folder)

db_target = DTB.ConnectDatabase(
    "inbopostgis_server.conf",
    connection_config = "loceval-testing",
    database = "loceval_testing"
    )
db = DTB.Database( \
    structure_folder = structure_folder, \
    definition_csv = "TABLES.csv", \
    lazy_creation = False, \
    db_connection = db_target, \
    tabula_rasa = False
    )
