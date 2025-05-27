
# assert crs 31370
assert_31370 <- function(sf_obj){
  stopifnot(
    "crs 31370" = format(sf::st_crs(sf_obj)) == "BD72 / Belgian Lambert 72"
  )
  return(sf_obj)
}


# bbox and extent
get_x_extent <- function(box) abs(box[["xmax"]] - box[["xmin"]])
get_y_extent <- function(box) abs(box[["ymax"]] - box[["ymin"]])
get_extent <- function(box) sqrt(get_x_extent(box)^2+get_y_extent(box)^2)/2
