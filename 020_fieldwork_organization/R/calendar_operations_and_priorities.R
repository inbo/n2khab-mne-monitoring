
#' filter by year, but
#' already allow the first GWINST, GW*LEVREAD* & SPATPOSIT* FAGs from the
#' next years to be executed
filter_max_year_and_preponable_activities_gw <- function(
    .data,
    selected_year,
    remove_has_gw = FALSE
  ) {

  stopifnot("stringr" = require("stringr"))
  stopifnot("lubridate" = require("lubridate"))
  stopifnot("dplyr" = require("dplyr"))
  stopifnot("magrittr" = require("magrittr"))

  # ensure gw activities are labeled
  if (!("has_gw" %in% names(.data))) {
    .data %<>% flag_groundwater_scheme_has_gw()
    remove_has_gw <- TRUE
  }

  # filter
  .data %<>%
    dplyr::filter(
      lubridate::year(date_start) <= selected_year |
        (
          has_gw &
            stringr::str_detect(
              field_activity_group,
              "INST|LEVREAD|SPATPOSIT"
            ) &
            date_start == min(date_start)
        ),
      .by = c(stratum, grts_address, field_activity_group)
    )

  # optionally remove `has_gw` column
  if (remove_has_gw) {
    .data %<>%
      dplyr::select(-has_gw)
  }

  return(.data)
}


#' move the LOCEVAL fieldwork that was kept for main_year - 1, to main_year,
#' since that is indeed its meaning
format_dates_and_get_interval <- function(.data) {

  # .data %>%
  #   count(date_start, date_end, date_interval) %>%
  #   knitr::kable()

  .data %>%
    dplyr::mutate(
      dplyr::across(c(date_start, date_end), \(x) {
        if_else(
          lubridate::year(date_start) == main_year - 1 &
            stringr::str_detect(field_activity_group, "LOCEVAL"),
          x + years(1),
          x
        )
      }),
      date_interval = lubridate::interval(
        lubridate::force_tz(date_start, "Europe/Brussels"),
        lubridate::force_tz(date_end, "Europe/Brussels")
      )
    ) %>%
    return()

}


#' drop past activities
drop_past_activities <- function(.data, min_year) {
  .data %>%
    filter(year(date_start) >= min_year) %>%
    return()
}



#_______________________________________________________________________________
### Priorities

prioritize_gw_fieldwork <- function(.data) {
  .data %>%
    dplyr::mutate(
      priority_gw = case_when(
        # no priority is given to imported FAGs from old versions (these
        # READDIVER, CLEAN & SHALLSAMP FAGs can be done as it suits, in the
        # locations where LOCEVAL is already executed)
        !is.na(scheme_ps_oldtargetpanel) ~ NA_integer_,
        # switch priorities for PS1PANEL02 and PS1PANEL03 from 15 April on!
        stringr::str_detect(scheme_ps_targetpanels, "GW_03\\.3:(PS1PANEL02|PS2PANEL01)") ~ 1L,
        stringr::str_detect(scheme_ps_targetpanels, "GW_03\\.3:(PS1PANEL03|PS2PANEL02)") ~ 2L,
        stringr::str_detect(scheme_ps_targetpanels, "GW_03\\.3:(PS1PANEL04)") ~ 3L,
        stringr::str_detect(scheme_ps_targetpanels, "GW_03\\.3:(PS1PANEL0[56]|PS2PANEL03)") ~ 4L,
        stringr::str_detect(scheme_ps_targetpanels, "GW_03\\.3:(PS1PANEL07)") ~ 6L,
        stringr::str_detect(scheme_ps_targetpanels, "GW_03\\.3:(PS1PANEL01)") ~ 7L,
        stringr::str_detect(scheme_ps_targetpanels, "GW_03\\.3:(PS1PANEL08|PS2PANEL04)") ~ 8L,
        stringr::str_detect(scheme_ps_targetpanels, "GW_05\\.") ~ 11L
      )
    ) %>%
    return()
}

prioritize_surf_fieldwork <- function(.data) {
  .data %>%
    dplyr::mutate(
      priority_surf = case_when(
        stringr::str_detect(scheme_ps_targetpanels, "SURF_03\\.4_[a-z]+:PS\\dPANEL02") ~ 2L,
        stringr::str_detect(scheme_ps_targetpanels, "SURF_03\\.4_[a-z]+:PS\\dPANEL01") ~ 4L
      )
    ) %>%
    return()
}

prioritize_soil_fieldwork <- function(.data) {
  .data %>%
    dplyr::mutate(
      priority_soil = case_when(
        stringr::str_detect(scheme_ps_targetpanels, "SOIL_03\\.2:PS\\dPANEL02") ~ 7L,
        stringr::str_detect(scheme_ps_targetpanels, "SOIL_03\\.2:PS\\dPANEL01") ~ 8L,
        stringr::str_detect(scheme_ps_targetpanels, "SOIL_03\\.2:PS\\dPANEL03") ~ 9L,
        stringr::str_detect(scheme_ps_targetpanels, "SOIL_03\\.2:PS\\dPANEL04") ~ 10L
      )
    ) %>%
    return()
}

prioritize_mhq_fieldwork <- function(.data) {
  .data %>%
    dplyr::mutate(
      priority_mhq = case_when(
        stringr::str_detect(scheme_ps_targetpanels, "HQ.+:PS\\dPANEL01") ~ 3L
      )
    ) %>%
    return()
}

prioritize_all_fieldwork <- function(.data) {
  .data %>%
    prioritize_gw_fieldwork() %>%
    prioritize_surf_fieldwork() %>%
    prioritize_soil_fieldwork () %>%
    prioritize_mhq_fieldwork () %>%
    dplyr::mutate(
      priority = pmin(
        priority_gw,
        priority_surf,
        priority_soil,
        priority_mhq,
        na.rm = TRUE
      ),
    ) %>%
    dplyr::select(-matches("priority_.+")) %>%
    return()
}

generate_wait_columns <- function(.data) {
  .data %>%
    dplyr::mutate(
      wait_watersurface = str_detect(stratum, "^31|^2190_a"),
      wait_3260 = stratum == "3260",
      wait_7220 = str_detect(stratum, "^7220"),
      wait_floating = stratum == "7140_mrd",
      wait_any = if_any(starts_with("wait"))
    ) %>%
    dplyr::relocate(wait_any, .before = wait_watersurface) %>%
    return()
}
