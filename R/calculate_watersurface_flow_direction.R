
#' Calculate flow direction for a water surface
#'
#' Calculate the putative flow direction for a surface water body
#' based on the elevation/slope in a given band/strip around it.
#' All calculations will be performed in CRS 31370, hence the output
#' flow vector will be in meters.
#'
#' @details this is the slope-averaged flow direction between
#' cells in a coarse raster grid within a given radius around the location.
#' Uses `terra::terrain(coarse_raster, v = "flowdir", neighbors = 8)`.
#' calculation will go one stripe of coarse grid cells into the water body,
#' and up to the `flow_range` around it.
#'
#' @param water_polygon Water polygon of interest; an `sf` POLYGON object.
#' @param flow_range the buffer extent (in meters) around the location,
#'        which is used to query elevation and calculate flow.
#'        Units are those of the coordinates.
#' @param flow_cellsize the width of a cell in the resampled raster
#'        across which elevation is averaged to calculate flow.
#'        Units are those of the coordinates.
#' @param save_plot_filepath if this is not NA, a summary map of the
#'        flow calculation will be saved as "png" image to the given path.
#'
#' @return c(dx,dy) vector (in meters) of the average flow direction in a
#'        circular area around the location.
#'
calculate_watersurface_flow_direction <- function(
    water_polygon,
    flow_range = 128,
    flow_cellsize = 32,
    close_island_size = NA,
    save_plot_filepath = NA
  ) {

  stopifnot("dplyr" = require("dplyr"))
  stopifnot("sf" = require("sf"))
  stopifnot("inbospatial" = require("inbospatial"))

  source(here::here("..", "R", "geometry_helpers.R"))
  source(here::here("..", "R", "spatial_helpers.R"))

  # optionally close islands in the water polygon
  if (!is.na(close_island_size)) {
    water_polygon <- water_polygon %>%
      close_polygon(close_island_size)
  }

  # calculate the buffer stripe around the target water
  band_buffer <- st_difference(
    sf::st_buffer(water_polygon, flow_range-flow_cellsize),
    sf::st_buffer(water_polygon, -flow_cellsize)
    ) %>% suppressWarnings()
  # mapview(band_buffer)

  # query DHMV elevation for the extent of the buffer
  xtnt <- sf::st_bbox(band_buffer)
  band_raster <- inbospatial::get_coverage_wcs(
    wcs = "dhmv",
    bbox = xtnt,
    layername = "DHMVII_DTM_1m",
    version = "2.0.1",
    wcs_crs = "EPSG:31370",
    resolution = 1
  )

  # resample to a coarse grid
  coarse_grid <- terra::rast(
    nrows = (xtnt[["ymax"]] - xtnt[["ymin"]])/flow_cellsize,
    ncols = (xtnt[["xmax"]] - xtnt[["xmin"]])/flow_cellsize,
    xmin = xtnt[["xmin"]],
    xmax = xtnt[["xmax"]],
    ymin = xtnt[["ymin"]],
    ymax = xtnt[["ymax"]],
    )

  terra::crs(coarse_grid) <- "EPSG:31370"
  band_raster_coarse <- terra::resample(
    band_raster,
    coarse_grid,
    method = "lanczos"
    # method = "bilinear"
  )
  # plot(band_raster_coarse)

  # calculate/convert slope and flow
  slope <- terra::terrain(band_raster_coarse, v = "slope")
  flow <- terra::terrain(band_raster_coarse, v = "flowdir", neighbors = 8)

  flow_df <- terra::as.data.frame(flow, xy = TRUE) %>%
    left_join(
      terra::as.data.frame(slope, xy = TRUE),
      join_by(x, y)
    ) %>%
    filter(!is.na(slope))

  flow_sf <- sf::st_as_sf(flow_df, coords = c("x", "y"), crs = 31370)
  flow_sf <- flow_sf %>%
    sf::st_intersection(sf::st_geometry(band_buffer)) %>%
    suppressWarnings()
  # mapview(flow_sf, zcol = "slope")
  # mapview(flow_sf, zcol = "flowdir")

  flow_df <- cbind(
      sf::st_drop_geometry(flow_sf),
      dplyr::as_tibble(sf::st_coordinates(flow_sf))
    ) %>%
    rename(c("x" = "X", "y" = "Y"))

  # differentials
  fpx <- flow_df[["x"]]
  fpy <- flow_df[["y"]]
  fpz <- flow_df[["flowdir"]]
  fpv <- flow_df[["slope"]]

  direction <- 2*pi/8 * log2(fpz)
  direction[!is.finite(direction)] <- NA

  dx <- +1*cos(direction)
  dy <- -1*sin(direction)

  # plot(slope)
  # pracma::quiver(
  #   x = px,
  #   y = py,
  #   u = dx,
  #   v = dy,
  #   scale = 3,
  #   col = "darkorange"
  #   )

  # print(paste0(nancumsum(dx, pv), ", ", nancumsum(dy, pv)))

  # the flow vector
  flow_vector <- c(nancumsum(dx, fpv), nancumsum(dy, fpv))

  ## optionally store a quiver plot on a map for vizualization
  if (!is.na(save_plot_filepath)) {

    png(save_plot_filepath,
      width = 120,
      height = 120,
      units = "mm",
      res = 300
    )

    # raster background
    plot(band_raster)

    # flow per cell
    pracma::quiver(
      x = fpx,
      y = fpy,
      u = dx,
      v = dy,
      scale = 8,
      col = "gray"
    )

    xy <- sf::st_coordinates(
        water_polygon %>%
        sf::st_centroid()
      ) %>%
      suppressWarnings() %>%
      data.frame
    # message(xy)

    # average flow
    pracma::quiver(
      x = xy[[1]],
      y = xy[[2]],
      u = flow_cellsize * flow_vector[[1]],
      v = flow_cellsize * flow_vector[[2]],
      scale = 3,
      col = "darkorange"
    )

    dev.off()
  } # /plotting

  return(flow_vector)
}
