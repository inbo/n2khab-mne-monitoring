#!/usr/bin/env Rscript


convert_rast_to_matrix <- \(rs) as.matrix(rs, geom = "XY", wide = TRUE)


#' Extract an xyz point from a raster, given x- and y indices.
#' The center of the grid cells is returned for x and y.
#' (Optionally invert y-axis for matrix vs. image indexing.)
extract_raster_point_by_index <- function(spat_raster, ix, iy, y_invert = FALSE) {
  sdim <- ext(spat_raster)[]
  nx <- ncol(spat_raster) + 1
  ny <- nrow(spat_raster) + 1
  ax_x <- seq(sdim["xmin"], sdim["xmax"], length.out = nx)
  if (y_invert){
    ax_y <- seq(sdim["ymax"], sdim["ymin"], length.out = ny)
  } else {
    ax_y <- seq(sdim["ymin"], sdim["ymax"], length.out = ny)
  }

  # offset by half a box
  dx <- mean(diff(ax_x))
  dy <- mean(diff(ax_y))

  return(c(
    "x" = ax_x[[ix]] + dx / 2,
    "y" = ax_y[[iy]] + dy / 2,
    "z" = spat_raster[ix, iy][[1]]
  ))
}


#' Smooth a landscape via application of a 2D Gaussian.
#'
#' TODO By now, matrix must be square for Gaussian/Euclid ...
#'
#' @param spat_raster a terra::SpatRaster object
#' @param sigma width of prior 2D Gaussian smoothing
#' @return terra::SpatRaster, smoothed
#'
smooth_raster <- function(spat_raster, sigma) {

  # stopifnot("sf" = require("sf"))
  stopifnot("terra" = require("terra"))

  # trivial escape conditions
  if (sigma <= 0 || is.null(sigma) || is.na(sigma)) {
    return(spat_raster)
  }

  # extract the data
  data <- convert_rast_to_matrix(spat_raster)

  # compute the difference of all elements of one vector to each other
  self_difference <- \(vec) outer(X = vec, Y = vec, FUN = function(X, Y) Y - X )

  # calculate the Euclidean distance of the x and y columns in a data frame.
  Euclid <- \(x, y) sqrt(self_difference(x)^2 + self_difference(y)^2 )

  # cross distance calculation
  dist <- Euclid(seq_len(dim(data)[1]), seq_len(dim(data)[2]))

  weight <- dnorm(dist, 0, sigma)
  weight <- weight / colSums(weight)

  data_smoothed <- weight %*% data

  # work on a deep copy to set values in place
  #   https://rspatial.github.io/terra/reference/deepcopy.html?q=deep%20copy#null
  #   not: https://rspatial.github.io/terra/reference/inplace.html
  raster_smoothed <- terra::deepcopy(spat_raster)
  raster_smoothed[, ] <- data_smoothed

  # done.
  return(raster_smoothed)

}


#' A system execution wrapper around `mdenoise` by Sun et al. (2007).
#' <https://doi.org/10.1109/TVCG.2007.1065>
#'
#' applying the Sun et al. (2007) algorithm
#' "Fast and Effective Feature-Preserving Mesh Denoising"
#' but only in z direction
#' requires working `mdnoise` installation
#' via <https://grass.osgeo.org/grass-stable/manuals/addons/r.denoise.html>
#'   wget http://www.cs.cf.ac.uk/meshfiltering/index_files/Doc/mdsource.zip
#'   unzip mdsource.zip
#'   cd mdenoise
#'   g++ -o mdenoise mdenoise.cpp triangle.c
#'   ln -s `pwd`/mdenoise /usr/bin/mdenoise
#'
#' @param spat_raster a terra::SpatRaster object
#' @param n number of iterations (for mdenoise)
#' @param t threshold (for mdenoise)
#'
mdenoise <- function(spat_raster, n = 5, t = 0.93) {

  tmpfi <- tempfile(tmpdir = "/tmp", fileext = ".xyz")
  tmpfo <- tempfile(tmpdir = "/tmp", fileext = ".xyz")

  writeRaster(spat_raster, tmpfi, filetype = "XYZ", overwrite = TRUE)

  sys_command <- glue::glue(
    "mdenoise -i {tmpfi} -n {n} -t {t} -z -o {tmpfo}"
    )
  system(sys_command)

  xyz_denoised <- read.csv2(tmpfo, sep = " ", header = FALSE)
  raster_denoised <- terra::rast(xyz_denoised)
  crs(raster_denoised) <- crs(spat_raster)

  return(raster_denoised)
} # /mdenoise


#' A convenience wrapper around terra::resample.
#'
#' Bring a given raster image to a regular grid.
#' Uses the extent (bbox) of the input raster.
#'
#' @param spat_raster a terra::SpatRaster object
#' @param nrows target number of rows
#' @param ncols target number of columns
#' @param method cf. https://www.rdocumentation.org/packages/terra/versions/1.8-80/topics/resample
#' @param ... args forwarded to terra::resample
#' @return terra::SpatRaster, but resampled
#'
resample_to_grid <- function(spat_raster, nrows, ncols, method = "lanczos", ...) {

  stopifnot("terra" = require("terra"))

  # create the new grid
  grid_extent <- terra::ext(spat_raster)[]
  new_grid <- terra::rast(
    nrows = nrows,
    ncols = ncols,
    xmin = grid_extent[["xmin"]],
    xmax = grid_extent[["xmax"]],
    ymin = grid_extent[["ymin"]],
    ymax = grid_extent[["ymax"]],
  )
  terra::crs(new_grid) <- terra::crs(spat_raster)

  # resample
  raster_resampled <- terra::resample(
    spat_raster,
    new_grid,
    method = method,
    ...
  )

  # done.
  return(raster_resampled)

} # /resample_to_grid


#' Compute the watershed labels ("catchments"/segments) for a given surface area or landscape.
#'
#' This will calculate watershed clusters from a given set of continuous measurements on a surface.
#' For application with spatial rasters of DHMV elevation measurements (cf.
#' <https://inbo.github.io/inbospatial/articles/spatial_dhmv_query.html>).
#' Using the "rain"/"top-down" approach to follow virtual droplets from
#' every point on the grid to its associated local elevation minimum.
#' It is recommended to resample the landscape to a regular (coarse) grid.
#'
#' REFERENCES:
#' + J. Cousty, G. Bertrand, L. Najman and M. Couprie (2009). "Watershed Cuts: Minimum Spanning Forests and the Drop of Water Principle". IEEE Transactions on Pattern Analysis and Machine Intelligence 31(8) pp. 1362-1374, <https://inria.hal.science/hal-01113462/document>; <https://doi.org/10.1109/TPAMI.2008.173>
#' + Kai Lochbihler (2022). "Practice my R: Two options to implement the watershed segmentation". Personal blog; <https://lochbihler.nl/practice-your-r-two-options-to-implement-the-watershed-segmentation>
#'
#' @param spat_raster a terra::SpatRaster object
#' @return list with labels and local minima.
#'
compute_watershed <- function(spat_raster) {

  stopifnot("dplyr" = require("dplyr"))
  stopifnot("terra" = require("terra"))
  stopifnot("magic" = require("terra"))
  stopifnot("reshape2" = require("sf"))

  nx <- dim(spat_raster)[1]
  ny <- dim(spat_raster)[2]

  spat_matrix <- convert_rast_to_matrix(spat_raster)

  shift_vectors <- matrix(
    c(1, 1,   #1
      1, 0,   #2
      1, -1,  #3
      0, 1,   #4
      0, 0,   #5
      0, -1,  #6
      -1, 1,  #7
      -1, 0,  #8
      -1, -1),#9
      ncol = 2,
      byrow = TRUE
    )

  # shift the data and stack the shifted versions
  data_shifted <- array(0.0, dim = c(nx, ny, 9))
  for (i in 1:9) {
    data_shifted[, , i] <- magic::ashift(spat_matrix, v = shift_vectors[i, ])
  }

  # calculate flow direction by applying `which.min`
  flow_tensor <- reshape2::melt(
    apply(
      data_shifted,
      FUN = which.min,
      MARGIN = c(1, 2)
    )
  )

  # generate initial coordinates for each drop of the input matrix
  coords_initial <- expand.grid(
    seq(1, nx),
    seq(1, ny)
  )

  # initialize, then loop and let drops flow along the gradient
  changed <- TRUE
  coords_prev <- coords_initial
  coords_next <- coords_initial

  # drop flow loop
  while (changed) {
    # calculate new coordinates
    coords_next[, 1] <-
      coords_prev[, 1] - shift_vectors[
        flow_tensor[
            (coords_prev[, 2] - 1) * nx + coords_prev[, 1],
            3
          ],
        1
      ]
    coords_next[, 2] <-
      coords_prev[, 2] - shift_vectors[
        flow_tensor[
            (coords_prev[, 2] - 1) * ny + coords_prev[, 1],
            3
          ],
        2
      ]

    # boundary checks: flows get stuck there
    coords_next[coords_next[, 1] > nx, 1] <- nx
    coords_next[coords_next[, 2] > ny, 2] <- ny
    coords_next[coords_next[, 1] < 1, 1] <- 1
    coords_next[coords_next[, 2] < 1, 2] <- 1

    # check if anything changed
    if (all(coords_next == coords_prev)) {
      changed <- FALSE
    } else {
      # update coords_prev for next iteration
      coords_prev <- coords_next
    }
  }

  coords_final <- coords_prev
  # plot(coords_final, col = gray.colors(256))

  catchments <- cbind(
    coords_initial,
    coords_final %>%
      dplyr::left_join(
        coords_final %>%
          dplyr::distinct() %>%
          dplyr::mutate(i = seq_len(dplyr::n())),
        by = dplyr::join_by(Var1, Var2)
      ) %>%
      dplyr::select(i) %>%
      as.matrix()
  )
  # catchments <- catchments[, c(2, 1, 3)]
  # catchments[, 2] <- max(catchments[, 2]) + 1 - catchments[, 2]

  # raster_catch <- terra::deepcopy(spat_raster)
  # raster_catch[, ] <- catchments


  data_output <- matrix(0, nrow = nx, ncol = ny)
  loc_min <- as.integer(rownames(flow_tensor[flow_tensor[, 3] == 5, c(1, 2)]))

  for (i in 1:length(loc_min)) {
    data_output[
      seq(1, nx * ny)[
        (coords_final[, 2] - 1) * nx + coords_final[, 1] == loc_min[i]
      ]
    ] <- i
  }

  # data_output <- t(data_output)
  # data_output <- data_output[c(nx:1), , drop = FALSE]
  # data_output <- data_output[, c(ny:1), drop = FALSE]

  # lmin <- loc_min[[1]]

  get_min <- function(lmin) {
    sink <- catchments[lmin,c(2,1)]
    pnt <- extract_raster_point_by_index(
      spat_raster,
      sink[[1]],
      sink[[2]],
      y_invert = TRUE
    )
    return(c("n" = lmin, pnt))
  }

  minima <- bind_rows(lapply(
    loc_min,
    FUN = get_min
  ))


  raster_shed <- terra::deepcopy(spat_raster)
  raster_shed[, ] <- data_output

  return(list(
    "watershed" = raster_shed,
    "catchments" = catchments,
    "sinks" = minima
  ))

} # /compute_watershed
