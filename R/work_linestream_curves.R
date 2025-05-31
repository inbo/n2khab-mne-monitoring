
# geometry tools
source(here::here("..", "R", "geometry_helpers.R"))


#' Example query of a stream curve (from segment lines).
#'
#' This demonstrates one simple manner of retrieving a "curve"
#' which represents a water stream by a series of line segments
#' which are grouped in sets of 100m.
#' resampling is possible (using spline interpolation) to get
#' evenly spaced points close to the stream lines.
#' The whole stream will be returned, with the rank and
#' sequence number set to zero at the reference node.
#'
#' @details a linestream curve is defined as
#' a data frame of points (`c(x, y)`),
#' which are associated with a `$rank` (here: segment identifier)
#' and a `$sequence` (stream direction, upstream).
#' Typically we use the function
#'   `n2khab::read_watercourse_100mseg(element = "lines")`
#' to query these segments. However, other data sources are possible
#' if they fulfill these data structure requirements.
#'
#' @param vhag_code the identifier from "Vlaamse Hydrografische Atlas"
#' @param reference_rank a continuous number do order points on the
#'        stream (in upstream direction)
#' @param streamline_datasource option to provide the data source
#'        (usually `n2khab::read_watercourse_100mseg(element = "lines")`
#'        or a subset) to avoid repeated loading.
#' @param resample_m optional resampling interval to get evenly spaced points.
#'
#' @return a streamline_curve (data frame with columns x, y, rank, sequence)
#'
#' @examples
#' \dontrun{
#'   stream <- get_linestream_curve(vhag_code = 9574, reference_rank = 218821)
#' }
#'
get_linestream_curve <- function(
    vhag_code,
    reference_rank = 0,
    streamline_datasource = NA,
    resample_m = NA
  ) {

  # vhag_code <- 9574
  # reference_rank <- 218821

  # if not provided, load the data source
  if (all(is.na(streamline_datasource))) {
    streamline_datasource <- n2khab::read_watercourse_100mseg(element = "lines")
  }

  # message(vhag_code)
  # message(reference_rank)

  # filter the points of interest
  target_stream_points <- streamline_datasource %>%
    filter(vhag_code == as.numeric(vhag_code))

  # resample the streams
  if (!is.na(resample_m)) {
    target_stream_points <- dplyr::bind_rows(lapply(
      seq_len(nrow(target_stream_points)),
      FUN = function(i) {resample_linestream(
        target_stream_points[i,],
        resample_m = 1
        )}
    ))
  }

  # some points are duplicates
  # (endpoint of one segment == startpoint of next)
  # which would complicate tangent calculation.
  # this removes the duplicates, while preserving the other attributes.
  rank <- target_stream_points$rank
  coords <- data.frame(sf::st_coordinates(target_stream_points))
  coords$exclude <- FALSE
  # tail(head(coords, 32), 16)
  for (i in seq_len(nrow(coords)-1)) {
    this <- coords[i,]
    conseq <- coords[i+1,]
    coords[i, "exclude"] <- (this$X == conseq$X) &&
      (this$Y == conseq$Y) &&
      ((this$L1+1) == conseq$L1)
  }

  coords <- coords[!coords$exclude, c("X", "Y", "L1")]

  # store a sequence of occurrence
  coords$sequence <- seq_len(nrow(coords))

  # join them as a curve
  linestream_curve <- as.data.frame(
      cbind(rank, seq_along(rank))
    ) %>%
    setNames(c("rank", "L1")) %>%
    dplyr::left_join(coords, dplyr::join_by(L1))
  names(linestream_curve) <- c("rank", "lseq", "x", "y", "sequence")

  # sort by "rank", i.e. point number
  linestream_curve$rank <- linestream_curve$rank - reference_rank
  linestream_curve <- linestream_curve %>% dplyr::arrange(rank, sequence)

  # set the reference rank to zero
  ref_rank <- linestream_curve %>%
    filter(rank == 0) %>%
    dplyr::slice(1) %>%
    dplyr::pull(sequence)
  if (length(ref_rank) > 0) {
    linestream_curve$sequence <- linestream_curve$sequence - ref_rank
  }

  return(linestream_curve)
} # /get_linestream_curve




#' Resample line stream to get points in regular intervals along the line.
#'
#' @keywords internal
#'
#' used only in the context of loading a linestream
#' this applies spline interpolations, so outcome points
#' might be positioned slightly off the original linear segments
#' (especially around sharp bends).
#'
#' @param linestream a stream curve (data frame of points)
#'        with at least x, y, sequence, and rank.
#' @param resample_m regular interval (meters) of resampled points.
#' @param crs the coordinate reference system given to the outcome
#'
#' @return the resampled linestream curve.
#'
#' @examples
#' \dontrun{
#'   linestream <- get_pointstream_test_curve(vhag = 9574, segment_rank = 218821) %>%
#'     sf::st_as_sf(coords = c("x", "y"), crs = 31370)
#'   resample_linestream(stream, normed = TRUE, append = FALSE)
#' }
#'
resample_linestream <- function(linestream, resample_m = 1, crs = 31370) {

  stopifnot("pspline" = require("pspline"))
  stopifnot("sf" = require("sf"))
  stopifnot("terra" = require("terra"))

  # linestream <- test
  original <- sf::st_coordinates(linestream)
  if (nrow(original) < 6) {
    # fallback: resample with `sf`; points on straight lines
    resampled <- sf::st_cast(
      sf::st_line_sample(linestream, density = 1/resample_m),
      "LINESTRING"
    )
    resampled <- sf::st_as_sf(cbind(
      sf::st_drop_geometry(linestream),
      resampled
    ))
    sf::st_crs(resampled) <- crs
    return(resampled)
  }

  x <- original[,1]
  y <- original[,2]

  # the phase along the line
  adx <- abs(diff(x))
  ady <- abs(diff(y))
  dt <- sqrt(adx^2 + ady^2)
  t <- c(0, cumsum(dt))
  t <- t / max(t)
  s <- seq(0, max(t), length.out = 1 + round(max(cumsum(dt))) / resample_m)

  # spline resampling
  spline_x <- terra::predict(pspline::sm.spline(t, x), s, 0)
  spline_y <- terra::predict(pspline::sm.spline(t, y), s, 0)

  # plot(x, y, type = "o", col = "black")
  # lines(spline_x, spline_y, type = "o", col = "blue")

  # object type restoration
  resampled <- sf::st_linestring(cbind(spline_x, spline_y))
  resampled <- sf::st_as_sf(cbind(
    sf::st_drop_geometry(linestream),
    sf::st_sfc(resampled)
  ))
  sf::st_crs(resampled) <- crs

  return(resampled)
}



#' Calculate the tangents on a line stream curve.
#'
#' The tangent is here defined as the local first derivative
#' of a spline fit through the lines of the curve.
#' This uses the `rank` as the "temporal" vector for spline prediction.
#'
#' @param linestream_curve a stream curve (data frame of points)
#'        with at least x, y, sequence, and rank.
#' @param normed normalize the tangent vectors to unit length
#' @param append append the stream curve data frame, or return separately
#' @param second whether to calculate the second derivative (inversion points)
#'
#' @return tangent vectors (df[x, y]), optionally appended to the stream curve
#'
#' @examples
#' \dontrun{
#'   stream <- get_linestream_test_curve(vhag = 9574, segment_rank = 218821)
#'   get_linestream_tangent(stream, normed = TRUE, append = FALSE)
#' }
#'
get_linestream_tangent <- function(
    linestream_curve,
    normed = FALSE,
    append = FALSE,
    second_derivative = FALSE
    ) {

  # first derivative using splines
  # https://stackoverflow.com/a/61287125
  stopifnot("pspline" = require("pspline"))
  stopifnot("terra" = require("terra"))

  t <- -linestream_curve$sequence # ! inverted: water flow directed downstream
  x <- linestream_curve$x
  y <- linestream_curve$y

  if (length(t) <= 5) {
    linestream_curve$tx <- c(diff(x), 0)
    linestream_curve$ty <- c(diff(y), 0)
  } else {
    linestream_curve$tx <- terra::predict(pspline::sm.spline(t, x), t, 1)
    linestream_curve$ty <- terra::predict(pspline::sm.spline(t, y), t, 1)
  }
  # plot(t, linestream_curve$tx)
  # plot(t, linestream_curve$ty)

  # optionally append second derivative
  if ((length(t) > 5) && second_derivative) {
    linestream_curve$tx2 <- terra::predict(pspline::sm.spline(t, x), t, 2)
    linestream_curve$ty2 <- terra::predict(pspline::sm.spline(t, y), t, 2)
  }

  # optionally normalize
  tangent_norm <- function(x, y) sqrt((x**2) + (y**2))
  linestream_curve$nt <- tangent_norm(linestream_curve$tx, linestream_curve$ty)

  if (normed) {
    linestream_curve$tx <- linestream_curve$tx / linestream_curve$nt
    linestream_curve$ty <- linestream_curve$ty / linestream_curve$nt

    if (second_derivative) {
      n2 <- tangent_norm(linestream_curve$tx2, linestream_curve$ty2)
      linestream_curve$tx2 <- linestream_curve$tx2 / n2
      linestream_curve$ty2 <- linestream_curve$ty2 / n2
    }
  }

  # return appended or directly ("inplace = False")
  if (append) return(linestream_curve)
  if (second_derivative) return(linestream_curve[, c("rank", "tx2", "ty2")])
  return(linestream_curve[, c("rank", "tx", "ty")])
}


#' Calculate the linestream curve normals (based on tangents).
#'
#' By convention, normals are defined as -π/2 rotation (i.e. ccw orthogonal)
#' of the tangent vector.
#' This uses the `rank` as the "temporal" vector for spline prediction
#' and tangent derivation, then rotating the tangent (counter-clockwise).
#'
#' @details If user choses to `append = TRUE`, tangents will also be appended.
#'          Tangents will be re-calculated, even if they were already present
#'          in the curve, and putatively overwritten.
#'
#' @param linestream_curve a stream curve (data frame of points)
#'        with at least x, y and rank.
#' @param normed normalize the normal vectors to unit length
#' @param append append the stream curve data frame, or return separately
#'
#' @return normal vectors (df[x, y]),
#'         optionally appended to the linestream curve
#'
#' @examples
#' \dontrun{
#'   stream <- get_linestream_test_curve(vhag = 9574, segment_rank = 218821)
#'   get_linestream_normal(stream, normed = TRUE, append = FALSE)
#' }
#'
get_linestream_normal <- function(
    linestream_curve,
    normed = FALSE,
    append = FALSE
    ) {

  # ensure that the tangent is calculated
  # and, in fact, *overwrite* it.
  linestream_curve <- get_linestream_tangent(
    linestream_curve,
    normed = normed,
    append = TRUE,
    second = FALSE
  )

  # ... and extract the tangent
  tx <- linestream_curve$tx
  ty <- linestream_curve$ty

  # list of vectors for lapply
  tangents <- lapply(seq_along(tx), FUN = function(t) c(tx[t], ty[t]))

  # conventional rotation π/2 CCW -> normal
  normals <- dplyr::bind_rows(lapply(
    seq_along(tx),
    FUN = function(t) as.data.frame(rotate_2d_90ccw(tangents[[t]]))
  ))
  names(normals) <- c("nx", "ny")

  # head(cbind(linestream_curve, normals)) # cbind creates duplicate cols
  if (append) {
    # linestream_curve <- linestream_curve %>% select(-nx, -ny)
    linestream_curve$nx <- normals$nx
    linestream_curve$ny <- normals$ny
    return(linestream_curve)
  }

  return(normals)
}


#' Calculate curvature or curvature direction for a linestream segment.
#'
#' The stream is optionally smoothed (using `smoother::smth` with `sma`)
#' direction is coded as curvature sign (-1: left turn, +1: right turn)
#' but with 0: NA (usually occurring with identical consecutive stream points).
#' Curvature is defined as the (scalar) projection of the
#' connection vector between tangent and difference vector
#' onto the curve Normal.
#' Obviously, *curvature* depends on stream direction and the order of points.
#' It is zero on straight lines, and positive on rightward turns.
#'
#' @param linestream_curve a stream curve (data frame of points)
#'        with at least x, y and rank.
#' @param direction (bool) the option to only return the sign of curvature.
#' @param smooth_range passed to `window` keyword of `smoother::smth` with
#'        the `sma` method. If this is `NA`, no smoothing applies.
#'
get_linestream_curvature_direction <- function(
    linestream_curve,
    direction = TRUE,
    smooth_range = NA
  ) {

  # for the dot product
  stopifnot("geometry" = require("geometry"))
  stopifnot("smoother" = require("smoother"))

  # certainly calculate tangents
  linestream_curve <- get_linestream_tangent(
    linestream_curve,
    normed = TRUE,
    append = TRUE
  )

  # ... and also normals
  linestream_curve <- get_linestream_normal(
    linestream_curve,
    normed = TRUE,
    append = TRUE
  )

  # numeric difference vector
  dx <- diff(linestream_curve$x)
  dy <- diff(linestream_curve$y)

  # t <- linestream_curve$sequence[seq_along(dx)]
  # plot(t, dx)

  # normalize differentials
  l <- Euclid(dx, dy)
  dx <- dx / l
  dy <- dy / l

  # there are zero-length segments
  dx[is.na(dx)] <- 0
  dy[is.na(dy)] <- 0

  # tangents and normals
  tx <- linestream_curve$tx[seq_along(dx)]
  ty <- linestream_curve$ty[seq_along(dy)]
  nx <- linestream_curve$nx[seq_along(dx)]
  ny <- linestream_curve$ny[seq_along(dy)]

  # connection vector between tangent and difference vector
  ux <- dx - tx
  uy <- dy - ty

  # scalar of the connection vector onto the normal
  curvatures <- c(sapply(
    seq_along(l),
    FUN = function(t) unlist(geometry::dot(c(ux[t], uy[t]), c(nx[t], ny[t])))
  ), 0)

  # t <- linestream_curve$sequence[seq_along(curvatures)]
  # plot(t, curvatures, type = 'l')

  # optional: smoothing by Gaussian-weighted average
  if ((length(curvatures) > 8) && (!is.na(smooth_range))) {
    unsmoothed_curvatures <- curvatures

    # curvatures <- smoother::smth.gaussian(curvatures, alpha = smooth_range, tails = TRUE)
    curvatures <- smoother::smth(curvatures, method = "sma", window = smooth_range)

    # TODO: this is the simple moving average, applied to series of curvatres
    # but it should rather be calculated based on point distance

    # keep unsmoothed values for smoothing-na's
    curvatures[is.na(curvatures)] <- unsmoothed_curvatures[is.na(curvatures)]

    # t <- linestream_curve$sequence[seq_along(curvatures)]
    # plot(t, curvatures, type = 'l')
  }

  # either return the direction...
  if (direction) {
    # (-1: left turn, 0: NA, +1: right turn)
    dirn <- (2*as.numeric(curvatures < 0)) - 1
    dirn[is.na(dirn)] <- 0
    return(dirn)
  }

  # ... or the curvature
  return(curvatures)

}


#' A convenience wrapper for some detailed plot
#' of the flow direction, tangents/normals, and curvature direction.
#' @keywords internal
plot_linestream_flowdirection <- function(
    linestream_curve,
    scale = 16
  ) {

  x <- linestream_curve$x
  y <- linestream_curve$y
  tx <- linestream_curve$tx * scale
  ty <- linestream_curve$ty * scale
  nx <- linestream_curve$nx * scale
  ny <- linestream_curve$ny * scale
  curv <- linestream_curve$curv
  #  <- linestream_curve$curv_smth
  dirn <- linestream_curve$dirn
  # dirn_smth <- linestream_curve$dirn_smth
  nx <- nx * dirn
  ny <- ny * dirn # _smth
  nz <- !as.logical(as.integer(nx == 0) * as.integer(ny == 0))
  # col <- as.integer(dirn)+1
  color <- as.integer(dirn[nz])+3


  plot(x, y, asp = 1)
  graphics::arrows(x, y, x+tx, y+ty, col = "darkgray", length = 0.1)
  # graphics::arrows(x, y, x+nx, y+ny, col = "lightblue", length = 0.1)
  # graphics::arrows(x-tx2, y-ty2, x+tx2, y+ty2, col = "lightblue", length = 0.1)
  graphics::arrows(
    x[nz], y[nz],
    x[nz] +  nx[nz],
    y[nz] +  ny[nz], # dirn[nz] *
    col = color, length = 0.05
  )
}


#' Example procedure for streamline the linestream calculations.
#' @keywords internal
get_all_linestream_measures <- function(
    linestream_curve,
    normed = TRUE,
    smooth_range = NA
    ) {

  # numeric difference
  linestream_curve$dx <- c(diff(linestream_curve$x), 0)
  linestream_curve$dy <- c(diff(linestream_curve$y), 0)

  linestream_curve$dx[is.na(linestream_curve$dx)] <- 0
  linestream_curve$dy[is.na(linestream_curve$dy)] <- 0

  # tangent
  linestream_curve <- get_linestream_tangent(
    linestream_curve,
    normed = normed,
    append = TRUE,
    second = FALSE
  )

  # normal
  linestream_curve <- get_linestream_normal(
    linestream_curve,
    normed = normed,
    append = TRUE
  )

  # curvature and curvature direction
  linestream_curve$curv <- get_linestream_curvature_direction(linestream_curve, direction = FALSE, smooth_range = NA)
  linestream_curve$dirn <- get_linestream_curvature_direction(linestream_curve, direction = TRUE, smooth_range = NA)
  if (!is.na(smooth_range)) {
    linestream_curve$curv_smth <- get_linestream_curvature_direction(linestream_curve, direction = FALSE, smooth_range = smooth_range)
    linestream_curve$dirn_smth <- get_linestream_curvature_direction(linestream_curve, direction = TRUE, smooth_range = smooth_range)
  }

  # head(linestream_curve)
  return(linestream_curve)

}




### ARCHIVE

#' Attempt to get the order/sequence of water stream points correct
#' unused, since this was already the case in our data set
#' @keywords internal
correct_curvepoint_order <- function(curve, coordinate_columns = NA) {

  # iterate points (downstream)
  # cross-distance of downstream points
  # p = calculate mean diffvector of previous n points
  # n = normal <- rotate normed(p) by π/2
  # d = diffvector to next points
  # l = length projection to normal
  # minimize Euclid(c(l, d))

  # (alternative strategy: rotate xy all the time to direction)

  # curve <- data.frame(x = c(0, 1., 2.5, 1.8), y = c(0.0, 1., 2.0, 1.5))
  # curve <- test_curve

  if (any(is.na(coordinate_columns))) {
    coordinate_columns <- c("x", "y")
  }

  # use only coordinates
  xy <- as.matrix(curve[coordinate_columns])
  xy <- data.frame(sweep(xy, 2, xy[1,]))

  # predefine new and old running index
  xy$idx <- NA
  xy$run <- seq_len(nrow(xy))

  # cross distances (preallocated)
  cdists <- cross_distance(
    curve[[coordinate_columns[1]]],
    curve[[coordinate_columns[2]]]
  )

  # the first two points are set; they give the direction.
  xy[1, "idx"] <- 1
  xy[2, "idx"] <- 2

  # iteratively get the order of points,
  # based on previous direction vector and distance.
  for (i in 3:(nrow(xy))) {
    # i <- 3
    # i <- 4
    # we sit on point `i-1`, and want to find the best consecutive for `i`

    # these are the points determined previously
    set_points <- xy[!is.na(xy$idx), ]

    one_back <- set_points[set_points$idx == i-1, coordinate_columns]
    two_back <- set_points[set_points$idx == i-2, coordinate_columns]

    # their difference gives us a direction
    step_vector <- as.matrix(one_back - two_back)


    # these are the remaining points to be determined,
    # and their distances to current position
    next_points <- xy[is.na(xy$idx), ]
    next_dists <- cdists[xy$run == i-1, is.na(xy$idx)]


    if (vector_norm(step_vector) == 0){
      # sometimes, there are point duplicates, so we get no direction.
      projections <- rep(0, length(next_dists))
    } else {
      # the normal is orthogonal to the diff direction
      # step_normal <- normalize_vector(as.matrix(step_vector) %*% rotate_90_ccw)
      step_normal <- normalize_vector(rotate_2d_90ccw(step_vector))

      # we project all putative steps to the normal;
      # the longer the projection, the more we would turn
      putative_steps <- sweep(
          as.matrix(next_points[,coordinate_columns]), 2, as.matrix(one_back))
      projections <- t(abs(as.matrix(putative_steps) %*% t(step_normal)))
    }

    # projections <- rep(0, length(next_dists))

    # this is our OPTIMIZATION measure (to be minimized):
    # the Euclidean norm of the distance and projection
    projection_weight <- 1.0 # we could disfavor turns even more
    value <- Euclid(next_dists, projection_weight*projections)
    # value <- next_dists + 1*projections

    # find the best candidate
    candidate <- next_points[which.min(value), "run"]
    xy[candidate, "idx"] <- i

  }

  curve$streampoint_order <- xy[, "idx"]

  return(curve)

} # /correct_curvepoint_order
