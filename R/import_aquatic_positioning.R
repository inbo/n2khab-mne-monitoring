# import wrapper
#
# this script facilitates importing of the adjacent files
# which are relevant for the aquatic observation well positioning


# commonly used libraries (extensive list)
conflictRules("n2khab", exclude = c("read_schemes", "read_scheme_types"))

void <- suppressPackageStartupMessages
library("stringr")     |> void() # string ragging
library("dplyr")       |> void() # our favorite data wrangling toolbox
library("tidyr")       |> void() # data preparation and rearrangement
library("googledrive") |> void() # google drive data to/fro
library("inbospatial") |> void() # convenience functions for wfs and other queries
library("sf")          |> void() # spatial feature processing
library("terra")       |> void() # spatial raster data
library("mapview")     |> void() # show spatial features on a map
library("n2khab")      |> void() # n2khab data and common functions
library("n2khabmon")   |> void() # monitoring schemes for natura2000 habitats

mapviewOptions(fgb = FALSE) # https://stackoverflow.com/a/65485896

# print sample from sf objects
kableprint <- function(df, show_rows = 5) {
  knitr::kable(df[sample(seq_len(nrow(df)), show_rows), ])
}


# initialization
source(here::here("..", "R", "confirm_n2khab_data_consistency.R"))
source(here::here("..", "R", "google_drive_init.R"))

# basic helpers
source(here::here("..", "R", "geometry_helpers.R"))
source(here::here("..", "R", "spatial_helpers.R"))

# POC and sampling frames
source(here::here("..", "R", "manage_poc_rdata_file.R"))

# spatial operations
source(here::here("..", "R", "calculate_flow_direction.R"))
source(here::here("..", "R", "calculate_watersurface_flow_direction.R"))

# watersurfaces
source(here::here("..", "R", "determine_watersurface_target_area.R"))

# streams
source(here::here("..", "R", "work_pointstream_curves.R"))
source(here::here("..", "R", "work_linestream_curves.R"))

# springs
source(here::here("..", "R", "determine_spring_target_area.R"))
