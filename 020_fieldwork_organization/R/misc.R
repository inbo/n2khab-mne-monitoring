#' Collapse (unexpand) a data frame with a `stratum` column
#'
#' Collapses a data frame that has been the result of a n2khab::expand_types()
#' operation.
#'
#' The collapsing (unexpanding) comprises two aspects:
#'
#' - replacing subtype codes by their main type code (where the target
#' population is defined by the latter)
#' - adding units, associated with a main type, to each corresponding subtype
#' layer that triggered the expansion to the main type.
#'
#' In effect, 'collapsing' means leads to less stratum levels, but _more_ rows.
#'
#' @param df A data frame with a `stratum` column.
collapse_strata <- function(df) {
  df %>%
    mutate(
      stratum = case_match(
        stratum,
        "5130_hei" ~ "5130",
        "5130_kalk" ~ "5130",
        "rbbkam+" ~ "rbbkam",
        "rbbzil+" ~ "rbbzil",
        "9120_qb" ~ "9120",
        .default = stratum
      )
    ) %>%
    left_join(
      tribble(
        ~main_type, ~subtype,
        "2330", "2330_bu",
        "2330", "2330_dw",
        "6230", "6230_ha",
        "6230", "6230_hmo",
        "6230", "6230_hn",
        "91E0", "91E0_va",
        "91E0", "91E0_vm",
        "91E0", "91E0_vn"
      ),
      by = c("stratum" = "main_type"),
      relationship = "many-to-many"
    ) %>%
    mutate(
      stratum = ifelse(is.na(subtype), stratum, subtype) %>%
        as.character() %>%
        factor(levels = levels(n2khab_strata_expanded$stratum))
    ) %>%
    select(-subtype)
}
