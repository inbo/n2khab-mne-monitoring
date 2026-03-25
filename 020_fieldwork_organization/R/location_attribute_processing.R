

#' Nesting scheme, panelset, targetpanel; optional unique flattening
#'
#' merging scheme:module_combo_code:panel_set:targetpanel, still distinguishing
#' strata separately (even though they may share their location: this is unreal
#' in the case of multiple cell-centered strata). For now, not distinguishing
#' module_combo as explained above.
#' OR:
#' flatten scheme x panel set x targetpanel to unique strings per stratum x
#' location x FAG occasion. Note that the scheme_ps_targetpanels attribute is a
#' shrinked version of the one at the level of the whole sample (see sampling
#' unit attributes in the beginning), since we limited the activities to those
#' planned before main_year + 1 (sometimes later), and then generate
#' stratum_scheme_ps_targetpanels as a location attribute. So it says
#' specifically which schemes x panel sets x targetpanels are served by the
#' specific fieldwork at a specific date interval.
#'
nest_and_flatten_scheme_ps_targetpanel <- function(
    .data,
    use_unique = FALSE,
    spt_flattening_function = NULL
  ) {

  # select one of the default flattening methods
  if (is.null(spt_flattening_function)) {
    if (use_unique) {
      spt_flattening_function <- function(df) {
        stringr::str_flatten(unique(df$scheme_ps_targetpanel), collapse = " | ")
      }
    } else {
      spt_flattening_function <- function(df) {
        stringr::str_flatten(df$scheme_ps_targetpanel, collapse = " | ")
      }
    }
  }

  # concatenate the target column, nest, and flatten it
  .data %<>%
    dplyr::mutate(scheme_ps_targetpanel = str_glue(
      "{ scheme }:PS{ panel_set }{ targetpanel }"
    )) %>%
    dplyr::select(-scheme, -panel_set, -targetpanel) %>%
    tidyr::nest(
      scheme_ps_targetpanels = scheme_ps_targetpanel
    ) %>%
    dplyr::mutate(
      scheme_ps_targetpanels = map_chr(
        scheme_ps_targetpanels,
        spt_flattening_function
      ) %>% factor()
    )

  .data %>%
    return()
}


#' concatenating and flattening stratum, grts join method, and scheme-ps-tp
concatenate_stratum_scheme_ps_targetpanels <- function(.data) {
  .data %>%
    dplyr::mutate(stratum_scheme_ps_targetpanels = str_c(
      stratum,
      " (",
      grts_join_method,
      ") ",
      " [",
      scheme_ps_targetpanels,
      "]"
    )) %>%
    dplyr::mutate(
      stratum_scheme_ps_targetpanels =
        str_flatten(stratum_scheme_ps_targetpanels, collapse = " \u2588 ") %>%
        factor(),
      .by = grts_address_final
    ) %>%
    return()
}



#' quick-select activities which are part of the groundwater scheme
flag_groundwater_scheme_has_gw <- function(.data) {

  stopifnot("stringr" = require("stringr"))
  stopifnot("dplyr" = require("dplyr"))
  stopifnot("magrittr" = require("magrittr"))

  if ("scheme" %in% names(.data)) {
    .data %<>%
      dplyr::mutate(
        has_gw = stringr::str_detect(scheme, "^GW")
      )
  } else if ("scheme_ps_targetpanels" %in% names(.data)) {
    .data %<>%
      dplyr::mutate(
        has_gw = stringr::str_detect(scheme_ps_targetpanels, "^GW")
      )

  } else if ("scheme_moco_ps" %in% names(.data)) {

    stopifnot("purrr" = require("purrr"))

    .data %<>%
      dplyr::mutate(
        has_gw = purrr::map_lgl(
          scheme_moco_ps,
          \(df) any(stringr::str_detect(df$scheme, "^GW"))
        )
      )
  } else {
    stop("ERROR in `flag_groundwater_scheme_has_gw`:
      no applicable `scheme*` column found in the provided data frame.")
  }

  return(.data)
}


#' generate some attributes of the FAG occasion with regard to associated schemes
generate_extra_scheme_attributes <- function(.data) {
  .data %>%
    mutate(
      schemes_served_all = map_chr(scheme_moco_ps, function(df) {
        str_flatten(df$scheme %>% unique() %>% sort(), collapse = "|")
      }) %>%
        factor(),
      nr_schemes_current = map_int(scheme_moco_ps, function(df) {
        sum(df$is_current_occasion)
      }),
      nr_schemes_later = map_int(scheme_moco_ps, function(df) {
        sum(!df$is_current_occasion)
      }),
      scheme_moco_ps = map(scheme_moco_ps, function(df) {
        df %>%
          filter(is_current_occasion) %>%
          select(scheme, module_combo_code, panel_set)
      })
    ) %>%
    return()

}



#' Derive an object where stratum x scheme_ps_targetpanels is flattened per
#' location x FAG occasion. Beware that in reality, more locations will emerge
#' due to local replacement, so this is misleading for counting & planning (but
#' useful in spatial visualization).
unite_stratum_and_schemepstargetpanels <- function(.data) {
  .data %>%
    mutate(
      stratum_scheme_ps_targetpanels = str_c(
        stratum,
        " (",
        grts_join_method,
        ") ",
        " [",
        scheme_ps_targetpanels,
        "]"
      ),
      .keep = "unused"
    ) %>%
    return()
}


#' converting stratum to type (in the usual way, although for the cell-based
#' units the values - but not the factor levels - are identical)
convert_stratum_to_type <- function(.data) {
  .data %>%
    im21_join(
      n2khab_strata,
      join_by(stratum)
    ) %>%
    dplyr::relocate(type, .after = stratum) %>%
    dplyr::select(-stratum) %>%
    return()
}



#' unnest schemes for which the FAG was originally planned in the current
#' date interval (is_current_occasion is TRUE), in order to add their
#' targetpanel attribute etc
join_location_attributes_via_moco <- function(.data) {

  .data %>%
    tidyr::unnest(scheme_moco_ps) %>%
    # adding location attributes
    im21_join(
      scheme_moco_ps_stratum_targetpanel_spsamples %>%
        dplyr::select(
          scheme,
          module_combo_code,
          panel_set,
          stratum,
          domain_part,
          grts_join_method,
          grts_address,
          grts_address_final,
          # retaining 3 cols that drive subsampling location(s) in the unit:
          is_forest,
          in_mhq_samples,
          last_type_assessment,
          last_type_assessment_in_field,
          targetpanel
        ) %>%
        # deduplicating 7220:
        dplyr::distinct(),
      dplyr::join_by(scheme, module_combo_code, panel_set, stratum, grts_address)
    ) %>%
    # add old targetpanel of the imported FAG occasions from rep_0.14.0. A part
    # is dropped because of occasions that don't happen in the main year.
    l121_join(
      cal_0.14.0_continuation %>%
        tidyr::unnest(scheme_moco_ps) %>%
        dplyr::mutate(
          scheme_ps_oldtargetpanel = str_c(scheme, ":PS", panel_set, targetpanel)
        ) %>%
        dplyr::select(
          -ends_with("upcoming"),
          -is_current_occasion,
          -date_interval,
          -targetpanel
        ),
      dplyr::join_by(
        scheme,
        module_combo_code,
        panel_set,
        stratum,
        grts_address,
        date_start,
        date_end,
        field_activity_group,
        rank
      )
    ) %>%
    dplyr::mutate(scheme_ps_oldtargetpanel = factor(scheme_ps_oldtargetpanel)) %>%
    dplyr::relocate(grts_address_final:domain_part, .after = grts_address) %>%
    dplyr::relocate(grts_join_method, .after = grts_address_final) %>%
    dplyr::relocate(scheme_ps_oldtargetpanel, .before = date_start) %>%
    dplyr::select(-module_combo_code) %>%
    return()

}


#' extract all `schemes` from the `scheme_ps_targetpanels` of a dataframe
#'
extract_and_flatten_scheme_from_scheme_ps_targetpanels <- function(.data) {

  check_presence_of_required_library("stringr")()
  check_presence_of_required_library("dplyr")()
  check_presence_of_required_library("purrr")()

  if (isFALSE("scheme_ps_targetpanels" %in% names(.data))) {
    message("WARNING: extraction of `schemes` requires the column `scheme_ps_targetpanels`.")
    return(.data)
  }

  if ("schemes" %in% names(.data)) {
    message("WARNING: column `schemes` is already found in the data -> NOOP.")
    return(.data)
  }

  extract_and_flatten_scheme_ <- function(txt) {
    txt %>%
      stringr::str_split("\\|") %>%
      purrr::map(stringr::str_trim) %>%
      purrr::map(\(schpata) sub(":.*", "", schpata)) %>%
      purrr::map(\(schpata) sort(unique(schpata))) %>%
      purrr::map(stringr::str_flatten, "|") %>%
      unlist() %>%
      return()
  }

  .data %>%
    dplyr::mutate(
      schemes = extract_and_flatten_scheme_(scheme_ps_targetpanels )
    ) %>%
    return()

}
