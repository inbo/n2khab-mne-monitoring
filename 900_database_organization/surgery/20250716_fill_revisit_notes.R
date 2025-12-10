
library("dplyr")
source("MNMDatabaseToolbox.R")



config_filepath <- file.path("./inbopostgis_server.conf")

db_name <- "loceval_testing"
connection_profile <- "loceval-testing"
db_connection <- connect_database_configfile(
  config_filepath = config_filepath,
  profile = connection_profile,
)


visits <- dplyr::tbl(db_connection, DBI::Id("inbound", "Visits")) %>%
  filter(visit_done, !is.na(notes)) %>%
  select(visit_id, sampleunit_id, notes) %>%
  collect() %>%
  knitr::kable()

SELECT visit_id, sampleunit_id, notes FROM "inbound"."Visits"
  WHERE visit_done
  AND notes IS NOT NULL;

SELECT sampleunit_id, recovery_hints FROM "outbound"."SampleUnits"
  WHERE recovery_hints IS NOT NULL;

"
| visit_id| sampleunit_id|notes                                                                        |
|--------:|-------------:|:----------------------------------------------------------------------------|
|      374|           374|Nauwkeurigheid 0,25                                                          |
|      686|           686|1 m nauwkeurigheid,  2 bamboe, 1 wit schijfje. Tussen zwarte bes en meidoorn |
|      564|           564|Nauwkeurigheid 0,95 m Wit meetschijfje, bamboe met blauwe top                |
|      308|           308|Zeer zwak ontwikkeld, nauwkeurigheid 0,25 m, celkartering niet nodig.        |
|      312|           312|Gemarkeerd met twee paaltjes                                                 |
"

|      686|           686|1 m nauwkeurigheid,  2 bamboe, 1 wit schijfje. Tussen zwarte bes en meidoorn |
UPDATE "outbound"."SampleUnits"
  SET recovery_hints = '2 bamboe, 1 wit schijfje. Tussen zwarte bes en meidoorn.'
  WHERE sampleunit_id = 686;
UPDATE "inbound"."Visits"
  SET notes = '1 m nauwkeurigheid'
  WHERE visit_id = 686;


|      564|           564|Nauwkeurigheid 0,95 m Wit meetschijfje, bamboe met blauwe top                |
UPDATE "outbound"."SampleUnits"
  SET recovery_hints = 'Wit meetschijfje, bamboe met blauwe top.'
  WHERE sampleunit_id = 564;
UPDATE "inbound"."Visits"
  SET notes = 'Nauwkeurigheid 0,95 m'
  WHERE visit_id = 564;

|      312|           312|Gemarkeerd met twee paaltjes                                                 |
UPDATE "outbound"."SampleUnits"
  SET recovery_hints = 'Gemarkeerd met twee paaltjes'
  WHERE sampleunit_id = 312;
UPDATE "inbound"."Visits"
  SET notes = NULL
  WHERE visit_id = 312;

UPDATE "outbound"."SampleUnits" SET recovery_hints = '' WHERE sampleunit_id = ;
UPDATE "inbound"."Visits" SET notes = '' WHERE visit_id = ;



# DONE!
