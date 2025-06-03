#' Add point coordinate columns to a data frame with a GRTS address column
#'
#' @param df Data frame.
#' @param grts_var String. The column name in df that holds the GRTS addresses.
#' @param spatrast SpatRaster object with level 0 GRTS addresses.
#' @param spatrast_index Data frame with columns 'id' and 'grts_address',
#'   holding the cell numbers (cell IDs) for each GRTS address in `spatrast`.
#' @param convert_to_sf_object Logical. Should the returned object
#'   be a sf points object? If `FALSE`,
#`   a data frame is returned with x and y coordinates as columns.
#'
#' @returns An sf points object or a tibble with coordinates, depending on the
#'   `convert_to_sf_object` argument.
add_point_coords_grts <- function(
    df,
    grts_var = "grts_address",
    spatrast = grts_mh_n2khab,
    spatrast_index = grts_mh_n2khab_index,
    convert_to_sf_object = TRUE) {
  addresses <- df %>%
    distinct(.data[[grts_var]]) %>%
    pull(.data[[grts_var]]) %>%
    sort()

  grts_cells <- spatrast_index %>%
    filter(grts_address %in% addresses) %>%
    arrange(grts_address) %>%
    pull(id)

  coords <- xyFromCell(spatrast, grts_cells)

  df %>%
    left_join(
      tibble(grts_address = addresses, x = coords[, "x"], y = coords[, "y"]),
      join_by({{ grts_var }} == grts_address)
    ) %>%
    {
      if (isFALSE(convert_to_sf_object)) {
        .
      } else {
        st_as_sf(., coords = c("x", "y"), crs = crs(spatrast))
      }
    }
}

#' Generate raster cells based on a vector of GRTS addresses
#'
#' Subsets the SpatRaster provided in the `spatrast` argument, using a vector of
#' either GRTS addresses or cell numbers.
#'
#' @param addresses Vector of integer GRTS addresses (level 0).
#' @inheritParams add_point_coords_grts
#' @param cells Vector of cell numbers to use; overrides addresses.
#' @param drop_address Logical. Should the non-missing values of the returned
#'   SpatRaster contain the original values, or should they be set as 1?
#' @param output_cell_nrs Logical. Should the function just return the cell
#'   numbers as an integer vector?
#'
#' @returns SpatRaster, or an integer vector if `output_cell_nrs` is `TRUE`.
filter_grtsraster_by_address <- function(
    addresses = NULL,
    spatrast = grts_mh_n2khab,
    spatrast_index = grts_mh_n2khab_index,
    cells = NULL,
    drop_address = FALSE,
    output_cell_nrs = FALSE) {
  if (is.null(cells)) {
    cells <- subset(spatrast_index, grts_address %in% addresses)$id
  }
  if (output_cell_nrs) {
    return(cells)
  }
  r <- spatrast[cells, drop = FALSE]
  if (drop_address) {
    r[!is.na(r)] <- 1
  }
  r
}



#' Generate the potential 'level 3' replacement GRTS cell numbers for a given
#' vector of GRTS addresses
#'
#' Given a vector of GRTS addresses, provides the cell numbers that fall inside
#' the enclosing larger 256 * 256 GRTS cell ('level 3 GRTS cell'). Note that
#' this result must still be limited to the cells of a specific polygon if this
#' is used for the polygon-constrained local replacement method.
#'
#' @inheritParams filter_grtsraster_by_address
#' @param spatrast_lev3 SpatRaster object with level 3 GRTS addresses, at the
#'   resolution of `spatrast`.
#' @param spatrast_lev3_index Data frame with columns 'id' and 'grts_address',
#'   holding the cell numbers for each GRTS address in `spatrast_lev3`.
#' @param as_list Logical. Should the result be given as a list, ordered so that
#'   the first element contains the replacement cell numbers corresponding to
#'   the first element of `addresses`, and so on? In this case, each element is
#'   a tibble of both the cell numbers and the GRTS address (level 0). Note that
#'   different GRTS addresses at level 0 may still yield the same set of
#'   replacement cell numbers if they reside in the same level 3 cell. If
#'   `FALSE`, a single vector is returned of unique cell numbers.
#'
#' @returns Vector or list, depending on the value of `as_list`.
get_level3replacement_cellnrs <- function(
    addresses,
    spatrast = grts_mh_n2khab,
    spatrast_index = grts_mh_n2khab_index,
    spatrast_lev3,
    spatrast_lev3_index,
    as_list = TRUE
) {
  id0 <- subset(spatrast_index, grts_address %in% unique(addresses))$id
  addr3 <- spatrast_lev3[id0]$level3
  id3 <- spatrast_lev3_index %>%
    filter(grts_address %in% unique(addr3)) %>%
    pull(id)
  if (!as_list) {
    id3
  } else {
    replacement_cells_grts03 <- tibble(
      cellnr_replac = id3,
      grts_address_replac = spatrast[id3][, 1],
      grts_address_replac_lev3 = spatrast_lev3[id3][, 1]
    )
    given_cells_grts03 <- replacement_cells_grts03 %>%
      select(-cellnr_replac) %>%
      filter(grts_address_replac %in% addresses) %>%
      rename(grts_address = grts_address_replac)
    sampledcells_replacementcells <-
      given_cells_grts03 %>%
      inner_join(
        replacement_cells_grts03,
        join_by(grts_address_replac_lev3),
        relationship = "many-to-many",
        unmatched = "error"
      ) %>%
      select(-grts_address_replac_lev3) %>%
      nest(replacement_cells = c(cellnr_replac, grts_address_replac))
    # following statement takes care to align the row order with the GRTS
    # addresses vector
    sampledcells_replacementcells[match(
      addresses,
      sampledcells_replacementcells$grts_address
    ), ]$replacement_cells
  }
}



#' Convert a vector of GRTS addresses to the corresponding level 3 addresses
#'
#' @inheritParams filter_grtsraster_by_address
#' @inheritParams get_level3replacement_cellnrs
convert_level0_to_level3 <- function(
    addresses,
    spatrast = grts_mh_n2khab,
    spatrast_index = grts_mh_n2khab_index,
    spatrast_lev3
) {
  result <- tibble(
    addr = addresses,
    id0 = spatrast_index[match(addresses, spatrast_index$grts_address), ]$id
  )
  id0_nona <- result$id0[!is.na(result$id0)] %>% unique()
  result %>%
    left_join(
      tibble(
        id0 = id0_nona,
        lev3addr = spatrast_lev3[id0_nona]$level3
      ),
      join_by(id0),
      relationship = "many-to-one",
      unmatched = "error"
    ) %>%
    pull(lev3addr)
}
