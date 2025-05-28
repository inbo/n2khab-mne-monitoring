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

### vector operations
# make sure an object is a vector
vectorize <- function(vec) sapply(seq_along(vec), FUN = function(i) vec[[i]])
# vectorize(as.matrix(c(0.1, 0.9)))

# vector norm
vector_norm <- function(vec) sqrt(sum(vectorize(vec)^2))
# vector_norm <- function(vec) sqrt(sum(sapply(seq_along(vec), FUN = function(v) vec[v]^2)))
# vector_norm(as.data.frame(c(0, 1, 1, 2)))

# normalize a vector
normalize_vector <- function(vec) vectorize(vec) / vector_norm(vectorize(vec))

# aggregate points in an arc around the center to cover all the belt
rotate_vec_2d <- function(vec, theta) vectorize(vec) %*% matrix(c(
   cos(theta), sin(theta),
  -sin(theta), cos(theta)
  ), ncol =2)
rotate_2d_90ccw <- function(vec) rotate_vec_2d(vec, -pi/2)
# rotate_vec(c(0.1, 0.9), 3*pi/4)
#
# # archive:
# rotate_90_ccw <- matrix(c(
#    cos(-pi/2), sin(-pi/2),
#   -sin(-pi/2), cos(-pi/2)
#   ), ncol =2)
# FUN = function(t) as.data.frame(tangents[[t]] %*% rotate_90_ccw)

dotproduct <- function (vec1, vec2) sum(vectorize(vec1) * vectorize(vec2))
# project_onto <- function(vec1, vec2) vec1 %*% vec2

# cross-calculation
cross_difference <- function(vec) outer(X = vec, Y = vec, FUN = function(X, Y) Y - X )
cross_distance <- function(x, y) Euclid(cross_difference(x), cross_difference(y))


### quick plotting
plot_arrow_from_center <- function(vec, ...){
  graphics::arrows(c(0), c(0), c(vec[1]), c(vec[2]), ...)
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
