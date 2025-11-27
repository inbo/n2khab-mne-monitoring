
# geometry tools
source(here::here("..", "R", "geometry_helpers.R"))


#' Example query of a stream curve (from segment points).
#'
#' This demonstrates one simple manner of retrieving a "curve"
#' which represents a water stream by points put on segments
#' of 100m length.
#'
#' @details a pointstream curve is defined as
#' a data frame of points (`c(x, y)`),
#' which are associated with a rank (stream direction).
#' Typically we use the function
#'   `n2khab::read_watercourse_100mseg(element = "points")`
#' to query these segments. However, other data sources are possible
#' if they fulfill these data structure requirements.
#'
#' @param vhag the identifier from "Vlaamse Hydrografische Atlas"
#' @param segment_rank a continuous number do order points on the
#'        stream (in upstream direction)
#'
#' @return a streampoint_curve (data frame with columns x, y, rank)
#'
#' @examples
#' \dontrun{
#'   stream <- get_pointstream_test_curve(vhag = 9574, segment_rank = 218821)
#' }
#'
get_pointstream_test_curve <- function(vhag, segment_rank) {

  stream_points <- n2khab::read_watercourse_100mseg(element = "points")
  # vhag <- 9574
  # segment_rank <- 218821


  # filter the points of interest
  target_stream_points <- stream_points %>%
    dplyr::filter(vhag_code == as.numeric(vhag))

  # join them as a curve
  stream_curve <- as.data.frame(
    cbind(target_stream_points$rank, sf::st_coordinates(target_stream_points))
  )
  names(stream_curve) <- c("rank", "x", "y")

  # sort by "rank", i.e. point number
  stream_curve$rank <- stream_curve$rank - segment_rank
  stream_curve <- stream_curve %>% dplyr::arrange(rank)

  return(stream_curve)
}



#' Plot a stream curve (from segment points)
#'
#' Plotting a stream curve, colored by rank.
#' No magic at all. Just a tiny convenience function.
#'
#' @param stream_curve a stream curve (data frame of points)
#'        with at least x, y and rank.
#'
#' @examples
#' \dontrun{
#'   stream <- get_pointstream_test_curve(vhag = 9574, segment_rank = 218821)
#'   plot_pointstream_curve(stream)
#' }
#'
plot_pointstream_curve <- function(stream_curve) {

  stopifnot("ggplot2" = require("ggplot2"))
  stream_curve %>%
    ggplot2::ggplot(ggplot2::aes(x = x, y = y)) +
      ggplot2::geom_path() +
      ggplot2::geom_point(aes(color = rank)) +
      ggplot2::coord_fixed(ratio = 1)
}



#' Calculate the tangents on a point stream curve.
#'
#' The tangent is here defined as the local first derivative
#' of a spline fit through the points of the curve.
#' This uses the `rank` as the "temporal" vector for spline prediction.
#'
#' @param stream_curve a stream curve (data frame of points)
#'        with at least x, y and rank.
#' @param normed normalize the tangent vectors to unit length
#' @param append append the stream curve data frame, or return separately
#' @param second whether to calculate the second derivative (inversion points)
#'
#' @return tangent vectors (df[x, y]), optionally appended to the stream curve
#'
#' @examples
#' \dontrun{
#'   stream <- get_pointstream_test_curve(vhag = 9574, segment_rank = 218821)
#'   get_pointstream_tangent(stream, normed = TRUE, append = FALSE)
#' }
#'
get_pointstream_tangent <- function(
    stream_curve,
    normed = FALSE,
    append = FALSE,
    second = FALSE
    ) {

  # first derivative using splines
  # https://stackoverflow.com/a/61287125
  stopifnot("pspline" = require("pspline"))
  stopifnot("terra" = require("terra"))

  t <- -stream_curve$rank # ! inverted: water flow directed downstream
  x <- stream_curve$x
  y <- stream_curve$y

  if (length(t) < 3) {
    stream_curve$tx <- c(diff(x), NA)
    stream_curve$ty <- c(diff(y), NA)
  } else {
    stream_curve$tx <- terra::predict(pspline::sm.spline(t, x), t, 1)
    stream_curve$ty <- terra::predict(pspline::sm.spline(t, y), t, 1)
  }

  # optionally append second derivative
  if (second) {
    stream_curve$tx2 <- terra::predict(pspline::sm.spline(t, x), t, 2)
    stream_curve$ty2 <- terra::predict(pspline::sm.spline(t, y), t, 2)
  }

  # optionally normalize
  stream_curve$nt <- Euclid(stream_curve$tx, stream_curve$ty)

  if (normed) {
    stream_curve$tx <- stream_curve$tx / stream_curve$nt
    stream_curve$ty <- stream_curve$ty / stream_curve$nt

    if (second) {
      n2 <- Euclid(stream_curve$tx2, stream_curve$ty2)
      stream_curve$tx2 <- stream_curve$tx2 / n2
      stream_curve$ty2 <- stream_curve$ty2 / n2
    }
  }

  # return appended or directly ("inplace = False")
  if (append) return(stream_curve)
  if (second) return(stream_curve[, c("rank", "tx2", "ty2")])
  return(stream_curve[, c("rank", "tx", "ty")])
}



#' Calculate the curve normals (based on tangents).
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
#' @param stream_curve a stream curve (data frame of points)
#'        with at least x, y and rank.
#' @param normed normalize the normal vectors to unit length
#' @param append append the stream curve data frame, or return separately
#'
#' @return normal vectors (df[x, y]), optionally appended to the stream curve
#'
#' @examples
#' \dontrun{
#'   stream <- get_pointstream_test_curve(vhag = 9574, segment_rank = 218821)
#'   get_pointstream_normal(stream, normed = TRUE, append = FALSE)
#' }
#'
get_pointstream_normal <- function(
    stream_curve,
    normed = FALSE,
    append = FALSE
    ) {

  # ensure that the tangent is calculated
  stream_curve <- get_pointstream_tangent(
    stream_curve,
    normed = normed,
    append = TRUE,
    second = FALSE
  )

  # ... and extract the tangent
  tx <- stream_curve$tx
  ty <- stream_curve$ty

  # list of vectors for lapply
  tangents <- lapply(seq_along(tx), FUN = function(t) c(tx[t], ty[t]))

  # conventional rotation -> normal
  rotate_90_ccw <- matrix(c(
     cos(-pi/2), sin(-pi/2),
    -sin(-pi/2), cos(-pi/2)
    ), ncol =2)
  normals <- dplyr::bind_rows(lapply(
    seq_along(tx),
    FUN = function(t) as.data.frame(tangents[[t]] %*% rotate_90_ccw)
  ))
  names(normals) <- c("nx", "ny")

  # head(cbind(stream_curve, normals)) # cbind creates duplicate cols
  if (append) {
    # stream_curve <- stream_curve %>% select(-nx, -ny)
    stream_curve$nx <- normals$nx
    stream_curve$ny <- normals$ny
    return(stream_curve)
  }

  return(normals)
}
