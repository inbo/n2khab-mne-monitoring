
# geometry tools
source(here::here("..", "R", "geometry_helpers.R"))


# for reference: this is how to get a pointstream curve
get_pointstream_test_curve <- function(vhag, segment_rank) {

  stream_points <- n2khab::read_watercourse_100mseg(element = "points")
  # vhag <- 9574
  # segment_rank <- 218821


  # filter the points of interest
  target_stream_points <- stream_points %>%
    filter(vhag_code == as.numeric(vhag))

  # join them as a curve
  stream_curve <- as.data.frame(
    cbind(target_stream_points$rank, sf::st_coordinates(target_stream_points))
  )
  names(stream_curve) <- c("rank", "x", "y")

  # sort by "rank", i.e. point number
  stream_curve$rank <- stream_curve$rank - segment_rank
  stream_curve <- stream_curve %>% arrange(rank)

  return(stream_curve)
}



# quick-plot a curve
plot_pointstream_curve <- function(stream_curve) {

  stopifnot("ggplot2" = require("ggplot2"))
  stream_curve %>%
    ggplot(ggplot2::aes(x = x, y = y)) +
      ggplot2::geom_path() +
      ggplot2::geom_point(aes(color = rank)) +
      coord_fixed(ratio = 1)
}




# the tangent at each segment point of the watercourse
get_pointstream_tangent <- function(
    stream_curve,
    normed = FALSE,
    append = FALSE,
    second = FALSE
    ) {

  # first derivative using splines
  # https://stackoverflow.com/a/61287125
  stopifnot("pspline" = require("pspline"))

  t <- -stream_curve$rank # ! inverted: water flow directed downstream
  x <- stream_curve$x
  y <- stream_curve$y

  if (length(t) < 3) {
    stream_curve$tx <- c(diff(x), NA)
    stream_curve$ty <- c(diff(y), NA)
  } else {
    stream_curve$tx <- predict(sm.spline(t, x), t, 1)
    stream_curve$ty <- predict(sm.spline(t, y), t, 1)
  }

  # optionally append second derivative
  if (second) {
    stream_curve$tx2 <- predict(sm.spline(t, x), t, 2)
    stream_curve$ty2 <- predict(sm.spline(t, y), t, 2)
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




# calculate the normals, based on tangents
# normals are defined as -π/2 rotation (ccw orthogonal) of the tangent
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
