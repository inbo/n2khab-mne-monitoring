
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



# get a point and a vector combined to an sf linestream
create_sf_vector <- function(pt, vec, unit_id) {
  line <- as.data.frame(rbind(pt, pt + vec)) %>%
    setNames(c("x", "y")) %>%
    sf::st_as_sf(coords = c("x", "y"), crs = 31370)

  line <- sf::st_sf(sf::st_combine(line) %>% st_cast("LINESTRING"))

  return(sf::st_sf(data.frame(unit_id = unit_id, geom = line)))
}
