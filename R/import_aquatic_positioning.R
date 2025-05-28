# import wrapper
#
# this script facilitates importing of the adjacent files
# which are relevant for the aquatic observation well positioning

# initialization
source(here::here("..", "R", "confirm_n2khab_data_consistency.R"))
source(here::here("..", "R", "google_drive_init.R"))

# basic helpers
source(here::here("..", "R", "geometry_helpers.R"))
source(here::here("..", "R", "spatial_helpers.R"))

# POC and sampling frames
source(here::here("..", "R", "download_poc_rdata_file.R"))
source(here::here("..", "R", "load_rdata_environment.R"))

# spatial operations
source(here::here("..", "R", "calculate_flow_direction.R"))
source(here::here("..", "R", "calculate_polygon_flow_direction.R"))
source(here::here("..", "R", "determine_watersurface_target_area.R"))

# streams
source(here::here("..", "R", "work_pointstream_curves.R"))
source(here::here("..", "R", "work_linestream_curves.R"))
