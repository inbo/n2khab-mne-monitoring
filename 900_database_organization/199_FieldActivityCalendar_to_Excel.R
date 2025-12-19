
library("dplyr")
library("rprojroot")

library("DBI")
library("RPostgres")

library("mapview")
# mapviewOptions(platform = "mapdeck")


source("MNMDatabaseToolbox.R")

projroot <- find_root(is_rstudio_project)
config_filepath <- file.path("./inbopostgis_server.conf")
working_dbname <- "loceval"
connection_profile <- "loceval"


db_connection <- connect_database_configfile(
  config_filepath,
  database = working_dbname,
  profile = connection_profile,
  user = "monkey",
  password = NA
)



fac <- dplyr::tbl(
    db_connection,
    DBI::Id("outbound", "FieldActivityCalendar")
  ) %>%
  select(
    -grts_address,
    -grts_join_method
  ) %>%
  collect()


fags <-
  dplyr::tbl(
    db_connection,
    DBI::Id(schema = "metadata", table = "GroupedActivities"),
  ) %>%
  distinct(activity_group_id, activity_group) %>%
  collect()



slocs <- dplyr::tbl(
  db_connection,
  DBI::Id("outbound", "SampleLocations")
) %>% collect()


calendar_preview <- slocs %>%
  inner_join(
    fac, by = "samplelocation_id"
  ) %>%
  inner_join(
    fags, by = "activity_group_id"
  ) %>%
  arrange(priority, date_start, activity_group)

knitr::kable(head(calendar_preview, 5))

calendar_preview %>% write.csv("data/fieldwork_calendar_preview.csv")
