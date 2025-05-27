# general helper functions

# remove nan
nonnan <- function(vec) vec[!is.na(vec)]

# mean, excluding NAs
nanmean <- function(vec) mean(nonnan(vec))

# Euclidean distance of elements of two vectors
Euclid <- function(x, y) sqrt(x^2 + y^2)

# filter coordinates within radius
within_radius <- function(x, y, r = 128) {
  dist <- Euclid(
    nonnan(x) - nanmean(x),
    nonnan(y) - nanmean(y)
  )
  return(dist < r)
}


### weighted vector averages
nonsel_nancumsum <- function (vec, weight) {

  vec <- as.matrix(vec)
  weight <- as.matrix(weight)

  nans <- is.na(vec) | is.na(weight)
  vec <- vec[!nans]
  weight <- weight[!nans]

  return(sum(vec * weight) / sum(weight))
}

nancumsum <- function (vec, weight, selection = NULL) {

  if (is.null(selection)) return(nonsel_nancumsum(vec, weight))

  # simplify input data types
  vec <- as.matrix(vec)
  weight <- as.matrix(weight)
  selection <- as.matrix(selection)

  # disregard NA's
  nans <- is.na(vec) | is.na(weight) | is.na(selection)
  vec <- vec[!nans]
  weight <- weight[!nans]
  selection <- selection[!nans]

  # return the weighted average of the vector
  return(sum(vec[selection] * weight[selection]) / sum(weight[selection]))
}


# calculate the average flow, but weighted and filtered
# (just a synonym for nancumsum)
average_flow <- nancumsum


### vector operations

# vector norm
vector_norm <- function(vec) sqrt(sum(vec^2))

# aggregate points in an arc around the center to cover all the belt
rotate_vec <- function(vec, theta) vec %*% matrix(c(
   cos(theta), sin(theta),
  -sin(theta), cos(theta)
  ), ncol =2)
