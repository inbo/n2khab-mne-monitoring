
#' rename the column `grts_address_final` to `grts_address`
#' (not used in these snippets, but afterwards)
#'
#' @param .data input data frame
#' @param keep_original toggle retention of the `grts_address` as `grts_address_original`
#'
rename_grts_address_final_to_grts_address <- function(.data, keep_original = FALSE) {

  .data %>%
    relocate(grts_address_final, .after = grts_address) %>%
    {
      if (keep_original) {
        # optionally rename the original grts address
        . %>% rename(grts_address_original = grts_address)
      } else {
        # (otherwise, drop original)
        . %>% select(-grts_address)
      }
    } %>%
    # simply rename
    rename(grts_address = grts_address_final) %>%
    return()
}
