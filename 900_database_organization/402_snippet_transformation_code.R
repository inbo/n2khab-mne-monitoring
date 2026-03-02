

common_current_calenderfilters <- function(.data) {

  stopifnot("dplyr" = require("dplyr"))
  stopifnot("stringr" = require("stringr"))
  stopifnot("purrr" = require("purrr"))

  if ("scheme_moco_ps" %in% names(.data)) {
    gw_data <- .data %>%
      dplyr::mutate(
        has_gw = purrr::map_lgl(
          scheme_moco_ps,
          \(df) any(stringr::str_detect(df$scheme, "^GW"))
        )
      )
  } else if ("scheme_ps_targetpanels" %in% names(.data)) {
    gw_data <- .data %>%
      dplyr::mutate(
        has_gw = stringr::str_detect(scheme_ps_targetpanels, "^GW")
      )

  }

  gw_data %>%
    filter(
      lubridate::year(date_start) < 2026 |
        # include groundwater cleaning & sampling activities from 2026
        (
          lubridate::year(date_start) < 2027 &
            str_detect(
              field_activity_group,
              "SHALL(CLEAN|SAMP)"
            )
        ) |
        # already allow the first GWINST, GW*LEVREAD* & SPATPOSIT* FAGs from the
        # next years to be executed:
        (
          has_gw &
            stringr::str_detect(
              field_activity_group,
              "INST|LEVREAD|SPATPOSIT"
            ) &
          date_start == min(date_start)
        ),
      .by = c(stratum, grts_address, field_activity_group)
    ) %>%
    select(-has_gw) %>%
    return()

}

common_current_samplefilters <- function(.data) {
  return(
    .data %>%
      filter(
        # only consider schemes scheduled in 2025:
        str_detect(scheme, "^(GW|HQ)"),
        # only keep cell-based types
        # (aquatic & 7220 will be more reliable or simply
        # not possible to evaluate on orthophoto)
        # str_detect(grts_join_method, "cell")
      )
  )
}

prioritize_and_arrange_fieldwork <- function(.data) {

  .data %>%
    mutate(
      priority = case_when(
        str_detect(scheme_ps_targetpanels, "GW_03\\.3:(PS1PANEL12|PS2PANEL06)") ~ 7L,
        str_detect(scheme_ps_targetpanels, "GW_03\\.3:(PS1PANEL11)") ~ 1L,
        str_detect(scheme_ps_targetpanels, "GW_03\\.3:(PS1PANEL10|PS2PANEL05)") ~ 2L,
        str_detect(scheme_ps_targetpanels, "GW_03\\.3:(PS1PANEL09)") ~ 3L,
        str_detect(scheme_ps_targetpanels, "SURF_03\\.4_[a-z]+:PS\\dPANEL03") ~ 4L,
        str_detect(scheme_ps_targetpanels, "GW_03\\.3:(PS1PANEL08|PS2PANEL04)") ~ 5L,
        str_detect(scheme_ps_targetpanels, "GW_03\\.3:(PS1PANEL07|PS2PANEL03)") ~ 6L,
        str_detect(scheme_ps_targetpanels, "GW_03\\.3:PS1PANEL0[56]") ~ 8L,
        .default = 9L
      ),
      wait_watersurface = str_detect(stratum, "^31|^2190_a"),
      wait_3260 = stratum == "3260",
      wait_7220 = str_detect(stratum, "^7220"),
      wait_floating = stratum == "7140_mrd",
      wait_any = if_any(starts_with("wait"))
    ) %>%
    relocate(wait_any, .before = wait_watersurface) %>%
    arrange(
      date_end,
      priority,
      wait_watersurface,
      wait_3260,
      wait_7220,
      wait_floating,
      wait_any,
      stratum,
      grts_address,
      rank,
      field_activity_group
    ) %>%
    return()


}

rename_grts_address_final_to_grts_address <- function(.data) {
  return(
  .data %>%
    select(-grts_address) %>%
    rename(
      grts_address = grts_address_final,
    )
  )
}

nest_scheme_ps_targetpanel <- function(.data) {
  # flatten scheme x panel set x targetpanel to unique strings per stratum x
  # location x FAG occasion. Note that the scheme_ps_targetpanels attribute is a
  # shrinked version of the one at the level of the whole sample (see sampling
  # unit attributes in the beginning), since we limited the activities to those
  # planned before 2026, and then generate stratum_scheme_ps_targetpanels as a
  # location attribute. So it says specifically which schemes x panel sets x
  # targetpanels are served by the specific fieldwork at a specific date
  # interval.
  .data %>%
    mutate(scheme_ps_targetpanel = str_glue(
      "{ scheme }:PS{ panel_set }{ targetpanel }"
    )) %>%
    select(-panel_set, -targetpanel) %>%
    nest(
      schemes = scheme,
      # panel_sets = panel_set,
      # targetpanels = targetpanel,
      scheme_ps_targetpanels = scheme_ps_targetpanel
    ) %>%
    mutate(
      schemes = map_chr(schemes, \(df) {
          str_flatten(unique(df$scheme), collapse = " | ")
        }),
      scheme_ps_targetpanels = map_chr(scheme_ps_targetpanels, \(df) {
          str_flatten(
            unique(df$scheme_ps_targetpanel),
            collapse = " | "
          )
        }) %>%
        factor()
    ) %>%
    relocate(scheme_ps_targetpanels, schemes) %>%
    return()
}

convert_stratum_to_type <- function(.data) {
  # converting stratum to type (in the usual way, although for the cell-based
  # units the values - but not the factor levels - are identical)
  return(
  .data %>%
    inner_join(
      n2khab_strata,
      join_by(stratum),
      relationship = "many-to-one",
      unmatched = c("error", "drop")
    ) %>%
    select(-stratum) %>%
    relocate(type, .after = sp_poststratum)
  )
}
