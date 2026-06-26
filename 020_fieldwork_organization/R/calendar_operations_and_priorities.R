
#' filter by year, but
#' already allow the first GWINST, GW*LEVREAD* & SPATPOSIT* FAGs from the
#' next years to be executed
filter_until_year_max_except_first_auxiliary_activities_gw <- function(
    .data,
    the_year_max,
    remove_has_gw = FALSE
  ) {

  require_pkgs(c("stringr", "lubridate", "dplyr"))
  stopifnot("magrittr" = require("magrittr"))


  if (!exists("filter_until_year_max_except_first_auxiliary_activities_gw")) {
    stop(
      " (in function `filter_until_year_max_except_first_auxiliary_activities_gw`)",
      "\n\tlookup `flag_groundwater_scheme_has_gw` is missing.",
      "\n\tPlease `source('location_attribute_processing.R')` first."
    )
  }

  # ensure gw activities are labeled
  if (!("has_gw" %in% names(.data))) {
    .data %<>% flag_groundwater_scheme_has_gw()
    remove_has_gw <- TRUE
  }

  # filter
  .data %<>%
    dplyr::filter(
      lubridate::year(date_start) <= the_year_max |
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


#' update the `date_interval`,
#' by simply overwriting it with `date_start` and `date_end`
update_date_interval <- function(.data) {

  require_pkgs(c("dplyr", "lubridate"))
  stopifnot("magrittr" = require("magrittr"))

  .data %>%
    dplyr::mutate(
      date_interval = lubridate::interval(
        lubridate::force_tz(date_start, "Europe/Brussels"),
        lubridate::force_tz(date_end, "Europe/Brussels")
      )
    ) %>%
    return()

}


#' move the LOCEVAL & SAMPLPOINT fieldwork that was kept for main_year - 1, to
#' main_year, since that is indeed its meaning
postpone_selected_past_activities <- function(.data) {

  require_pkgs(c("dplyr", "lubridate"))
  stopifnot("magrittr" = require("magrittr"))

  # .data %>%
  #   count(date_start, date_end, date_interval) %>%
  #   knitr::kable()

  .data %>%
    dplyr::mutate(
      dplyr::across(c(date_start, date_end), \(x) {
        dplyr::if_else(
          lubridate::year(date_start) == main_year - 1 &
            stringr::str_detect(field_activity_group, "LOCEVAL|SAMPLPOINT"),
          x + lubridate::years(1),
          x
        )
      })
    ) %>%
    update_date_interval() %>%
    return()

}


#' drop past activities
drop_past_activities <- function(.data, min_year) {

  require_pkgs("dplyr")
  stopifnot("magrittr" = require("magrittr"))

  .data %>%
    dplyr::filter(lubridate::year(date_start) >= min_year) %>%
    return()

}


#' Mark matching occasions
#'
#' Marks matching occasions in a data frame of FAG occasions.
#'
#' In lentic types, multiple strata can effectively occur at the same GRTS
#' address. Such rows represent duplicated FAG occasions. In some of these
#' cases (LOCEVALAQ) data must still be collected with reference to the
#' specific stratum, but the actual fieldwork is just a single occasion. Since
#' we need the distinction between strata for the terrestrial FAG occasions and
#' because the sampling units always remain defined by grts_address x stratum,
#' we don't change the object structure to reflect unique fieldwork events.
#' However we do mark some FAG occasions as 'matching occasions' using a common
#' string: these FAG occasions occur more than once across strata (and for some
#' FAGs also across time) and can be executed as a single FAG occasion.
mark_matching_occasions <- function(.data) {
  require_pkgs(c("dplyr", "lubridate", "stringr", "magrittr"))
  .data %>%
    # matching occasions across strata
    dplyr::mutate(
      matching_occasion = ifelse(
        stringr::str_detect(stratum, "^2190_a|^31") &
          # not using n() because that still includes terrestrial types:
          sum(stringr::str_detect(stratum, "^2190_a|^31")) > 1,
        stringr::str_c(
          dplyr::first(field_activity_group),
          dplyr::first(grts_address_final),
          stringr::str_c(
            "[",
            format(dplyr::first(date_start), "%Y%m%d"),
            "-",
            format(dplyr::first(date_end), "%Y%m%d"),
            "]"
          ),
          sep = "_"
        ),
        NA_character_
      ),
      .by = c(grts_address, starts_with("date"), field_activity_group)
    ) %>%
    # matching occasions across strata and date intervals
    dplyr::mutate(
      matching_occasion = ifelse(
        stringr::str_detect(stratum, "^2190_a|^31") &
          # not using n() because that still includes terrestrial types:
          sum(stringr::str_detect(stratum, "^2190_a|^31")) > 1 &
          stringr::str_detect(field_activity_group, "INST|LEVREAD|SPATPOSIT"),
        stringr::str_c(
          dplyr::first(field_activity_group),
          dplyr::first(grts_address_final),
          sep = "_"
        ),
        matching_occasion
      ),
      .by = c(grts_address, field_activity_group)
    ) %>%
    dplyr::mutate(matching_occasion = factor(matching_occasion)) %>%
    return()
}


#_______________________________________________________________________________
### Priorities

prioritize_gw_fieldwork <- function(.data) {

  require_pkgs(c("dplyr", "stringr"))
  stopifnot("magrittr" = require("magrittr"))

  .data %>%
    dplyr::mutate(
      priority_gw = dplyr::case_when(
        # no priority is given to imported FAGs from old versions (these
        # READDIVER, CLEAN & SHALLSAMP FAGs can be done as it suits, in the
        # locations where LOCEVAL is already executed)
        !is.na(scheme_ps_oldtargetpanels_served) ~ NA_integer_,
        # no priority is given to FAG occasions for types that will be obsoleted,
        # if the panel set is panel set 2 accross the targeted schemes
        stratum %in% c("6410_ve", "6510_hus") &
          !stringr::str_detect(scheme_ps_targetpanels_served, ":PS1") ~ NA_integer_,
        stringr::str_detect(scheme_ps_targetpanels_served, "GW_03\\.3:(PS1PANEL03|PS2PANEL01)") ~ 1L,
        stringr::str_detect(scheme_ps_targetpanels_served, "GW_03\\.3:PS2PANEL02") ~ 2L,
        stringr::str_detect(scheme_ps_targetpanels_served, "GW_03\\.3:PS1PANEL02") ~ 9L,
        stringr::str_detect(scheme_ps_targetpanels_served, "GW_03\\.3:PS1PANEL04") ~ 3L,
        stringr::str_detect(scheme_ps_targetpanels_served, "GW_03\\.3:(PS1PANEL0[56]|PS2PANEL03)") ~ 4L,
        stringr::str_detect(scheme_ps_targetpanels_served, "GW_03\\.3:PS1PANEL07") ~ 6L,
        stringr::str_detect(scheme_ps_targetpanels_served, "GW_03\\.3:PS1PANEL01") ~ 10L,
        stringr::str_detect(scheme_ps_targetpanels_served, "GW_03\\.3:(PS1PANEL08|PS2PANEL04)") ~ 8L,
        stringr::str_detect(scheme_ps_targetpanels_served, "GW_05\\.") ~ 11L
      )
    ) %>%
    return()

}

prioritize_surf_fieldwork <- function(.data) {

  require_pkgs(c("dplyr", "stringr"))
  stopifnot("magrittr" = require("magrittr"))

  .data %>%
    dplyr::mutate(
      priority_surf = dplyr::case_when(
        stringr::str_detect(scheme_ps_targetpanels_served, "SURF_03\\.4_[a-z]+:PS\\dPANEL02") ~ 2L,
        stringr::str_detect(scheme_ps_targetpanels_served, "SURF_03\\.4_[a-z]+:PS\\dPANEL01") ~ 4L
      )
    ) %>%
    return()

}

prioritize_soil_fieldwork <- function(.data) {

  require_pkgs(c("dplyr", "stringr"))
  stopifnot("magrittr" = require("magrittr"))

  .data %>%
    dplyr::mutate(
      priority_soil = dplyr::case_when(
        # no priority is given to FAG occasions for types that will be obsoleted,
        # if the panel set is panel set 2 accross the targeted schemes
        stratum %in% c("6410_ve", "6510_hus") &
          !stringr::str_detect(scheme_ps_targetpanels_served, ":PS1") ~ NA_integer_,
        stringr::str_detect(scheme_ps_targetpanels_served, "SOIL_03\\.2:PS\\dPANEL02") ~ 7L,
        stringr::str_detect(scheme_ps_targetpanels_served, "SOIL_03\\.2:PS\\dPANEL01") ~ 8L,
        stringr::str_detect(scheme_ps_targetpanels_served, "SOIL_03\\.2:PS\\dPANEL03") ~ 9L,
        stringr::str_detect(scheme_ps_targetpanels_served, "SOIL_03\\.2:PS\\dPANEL04") ~ 10L
      )
    ) %>%
    return()

}

prioritize_mhq_fieldwork <- function(.data) {

  require_pkgs(c("dplyr", "stringr"))
  stopifnot("magrittr" = require("magrittr"))

  .data %>%
    dplyr::mutate(
      priority_mhq = dplyr::case_when(
        # no priority is given to FAG occasions for types that will be obsoleted,
        # if the panel set is panel set 2 accross the targeted schemes
        stratum %in% c("6410_ve", "6510_hus") &
          !stringr::str_detect(scheme_ps_targetpanels_served, ":PS1") ~ NA_integer_,
        stringr::str_detect(scheme_ps_targetpanels_served, "HQ.+:PS\\dPANEL01") ~ 3L
      )
    ) %>%
    return()

}

prioritize_all_fieldwork <- function(.data) {

  require_pkgs(c("dplyr", "stringr"))
  stopifnot("magrittr" = require("magrittr"))

  .data %>%
    prioritize_gw_fieldwork() %>%
    prioritize_surf_fieldwork() %>%
    prioritize_soil_fieldwork() %>%
    prioritize_mhq_fieldwork() %>%
    dplyr::mutate(
      priority = pmin(
        priority_gw,
        priority_surf,
        priority_soil,
        priority_mhq,
        na.rm = TRUE
      ),
    ) %>%
    dplyr::select(-dplyr::matches("priority_.+")) %>%
    return()

}

add_wait_columns <- function(.data) {

  require_pkgs(c("dplyr", "stringr"))
  stopifnot("magrittr" = require("magrittr"))

  .data %>%
    dplyr::mutate(
      wait_watersurface = stringr::str_detect(stratum, "^2190_a") |
        (
          stringr::str_detect(stratum, "^31|^2190_a") &
            !stringr::str_detect(schemes_served_all, "SURF_03\\.4")
        ),
      wait_3260 = stratum == "3260",
      wait_7220 = stringr::str_detect(stratum, "^7220"),
      wait_floating = stratum == "7140_mrd",
      wait_mhq = stringr::str_detect(scheme_ps_targetpanels_served, "^HQ.*?(?!\\|)"),
      wait_obsolete_types = stratum %in% c("6410_ve", "6510_hus") &
        (
          # don't pursue locations (including LOCEVAL FAGs) that only belong to
          # panel set 2, except for planned READDIVER, CLEAN & SHALLSAMP FAGs
          # (i.e. applicable to already installed locations)
          (
            !stringr::str_detect(scheme_ps_targetpanels_served, ":PS1") &
              !stringr::str_detect(field_activity_group, "^GW.*(LEVREADDIVER|SHALL)")
          ) |
            # for panel set 1, don't perform new installations in these types, but
            # other activities including LOCEVAL can still be planned
            stringr::str_detect(field_activity_group, "INST")
        ),
      wait_any = dplyr::if_any(dplyr::starts_with("wait"))
    ) %>%
    dplyr::relocate(wait_any, .before = wait_watersurface) %>%
    return()

}
