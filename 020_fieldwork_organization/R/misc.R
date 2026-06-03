#' subset data to proceed only on `cell`-type sample support code
filter_for_cells <- function(.data) {
  require_pkgs(c("stringr", "dplyr"))

  .data %>%
    dplyr::filter(
      stringr::str_detect(sample_support_code, "cell")
    ) %>%
    return()
}
