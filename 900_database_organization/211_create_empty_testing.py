import MNMDatabaseToolbox as DTB

# database:
base_folder = DTB.PL.Path(".")
structure_folder = base_folder/"devdb_structure"
DTB.ODStoCSVs(base_folder/"loceval_dbstructure.ods", structure_folder)

db_target = DTB.ConnectDatabase(
    "inbopostgis_server.conf",
    connection_config = "testing",
    database = "loceval_testing"
    )
db = DTB.Database( \
    structure_folder = structure_folder, \
    definition_csv = "TABLES.csv", \
    lazy_creation = False, \
    db_connection = db_target, \
    tabula_rasa = False
    )
