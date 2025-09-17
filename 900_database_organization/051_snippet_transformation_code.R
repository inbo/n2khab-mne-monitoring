

common_current_calenderfilters <- function(.data) {
  .data %>%
  mutate(has_gw = purrr::map_lgl(
    scheme_moco_ps,
    \(df) any(stringr::str_detect(df$scheme, "^GW"))
  )) %>%
  filter(
    lubridate::year(date_start) < 2026 |
      # already allow GWINST, GW*LEVREAD* & SPATPOSIT* FAGs from 2026 to be
      # executed in 2025:
      (
        (lubridate::year(date_start) < 2027) &
          has_gw &
          str_detect(
            field_activity_group,
            "INST|LEVREAD|SPATPOSIT"
          )
      )
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

  return(
  .data %>%
    mutate(
      priority = case_when(
        str_detect(
          scheme_ps_targetpanels,
          "GW_03\\.3:(PS1PANEL(09|10|11|12)|PS2PANEL0[56])|SURF_03\\.4_[a-z]+:PS\\dPANEL03"
        ) ~ 1L,
        str_detect(scheme_ps_targetpanels, "GW_03\\.3:(PS1PANEL08|PS2PANEL04)") ~ 2L,
        str_detect(scheme_ps_targetpanels, "GW_03\\.3:(PS1PANEL07|PS2PANEL03)") ~ 3L,
        str_detect(scheme_ps_targetpanels, "GW_03\\.3:PS1PANEL0[56]") ~ 4L,
        .default = 5L
      ),
      wait_watersurface = str_detect(stratum, "^31|^2190_a$"),
      wait_3260 = stratum == "3260",
      wait_7220 = str_detect(stratum, "^7220")
    )
  ) %>%
  arrange(
    date_end,
    priority,
    wait_watersurface,
    wait_3260,
    wait_7220,
    stratum,
    grts_address,
    rank,
    field_activity_group
  )
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
  return(
  .data %>%
    mutate(scheme_ps_targetpanel = str_glue(
      "{ scheme }:PS{ panel_set }{ targetpanel }"
    )) %>%
    nest(scheme_ps_targetpanels = scheme_ps_targetpanel) %>%
    mutate(
      scheme_ps_targetpanels = map_chr(scheme_ps_targetpanels, \(df) {
        str_flatten(
          unique(df$scheme_ps_targetpanel),
          collapse = " | "
        )
      }) %>%
        factor()
    ) %>%
    relocate(scheme_ps_targetpanels)
  )
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
