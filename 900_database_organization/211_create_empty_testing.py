import MNMDatabaseToolbox as DTB

# database:
base_folder = DTB.PL.Path(".")
DTB.ODStoCSVs(base_folder/"loceval_dbstructure.ods", base_folder/"db_structure")

db_target = DTB.ConnectDatabase(
    "inbopostgis_server.conf",
    connection_config = "inbopostgis-dev",
    database = "loceval_testing"
    )
db = DTB.Database( \
    structure_folder = "./devdb_structure", \
    definition_csv = "TABLES.csv", \
    lazy_creation = False, \
    db_connection = db_target, \
    tabula_rasa = False
    )
