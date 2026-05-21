#' Nesting scheme, panelset, targetpanel; unique flattening
#'
#' flatten scheme x panel set x targetpanel to unique strings
#' per stratum x location x FAG occasion.
#' the "old scheme" can be included, optionally
nest_and_flatten_scheme_ps_targetpanel <- function(
  .data,
  spt_flattening_function = NULL,
  include_old = TRUE
) {

  require_pkgs(c("tidyr", "dplyr", "stringr", "purrr"))
  stopifnot("magrittr" = require("magrittr"))

  # select one of the default flattening methods
  if (is.null(spt_flattening_function)) {
    spt_flattening_function <- function(df) {
      stringr::str_flatten(unique(df$scheme_ps_targetpanel), collapse = " | ")
    }
  }

  # concatenate the target column, nest, and flatten it
  if (include_old) {
    # if old panels are included, NA targetpanel must be fixed
    data_spst <- .data %>%
      dplyr::mutate(
        scheme_ps_targetpanel = ifelse(
          is.na(targetpanel),
          as.character(scheme_ps_oldtargetpanel),
          stringr::str_glue("{ scheme }:PS{ panel_set }{ targetpanel }")
        )
      )
  } else {
    data_spst <- .data %>%
      dplyr::mutate(
        scheme_ps_targetpanel = stringr::str_glue(
          "{ scheme }:PS{ panel_set }{ targetpanel }"
        )
      )
  }

  # nest and flatten scheme_ps_targetpanel
  data_spst <- data_spst %>%
    dplyr::select(-scheme, -panel_set, -targetpanel) %>%
    tidyr::nest(
      scheme_ps_targetpanels = scheme_ps_targetpanel
    ) %>%
    dplyr::mutate(
      scheme_ps_targetpanels = purrr::map_chr(
        scheme_ps_targetpanels,
        spt_flattening_function
      ) %>% factor()
    )


  if (isFALSE(include_old)) {
    # if old panels are not included, they are retained as separate column
    data_spst <- data_spst %>%
      dplyr::mutate(
        scheme_ps_oldtargetpanels = purrr::map_chr(
          scheme_ps_oldtargetpanels,
          \(df) {
            stringr::str_flatten(
              unique(df$scheme_ps_oldtargetpanel),
              collapse = " | "
            )
          }
        ) %>%
        factor()
      )
  }

  data_spst %>%
    return()
}



#' Nesting current and old scheme, panelset, targetpanel; unique flattening
#'
#' flatten current and old scheme x panel set x targetpanel to unique strings
#' per stratum x location x FAG occasion.
nest_and_flatten_scheme_ps_targetpanel_include_old_OBSOLETE <- function(
    .data,
    spt_flattening_function = NULL
  ) {

  require_pkgs(c("tidyr", "dplyr", "stringr", "purrr"))
  stopifnot("magrittr" = require("magrittr"))

  # select one of the default flattening methods
  if (is.null(spt_flattening_function)) {
    spt_flattening_function <- function(df) {
      stringr::str_flatten(unique(df$scheme_ps_targetpanel), collapse = " | ")
    }
  }

  # concatenate the target column, nest, and flatten it
  .data %<>%
    dplyr::mutate(scheme_ps_targetpanel = ifelse(
      is.na(targetpanel),
      as.character(scheme_ps_oldtargetpanel),
      stringr::str_glue("{ scheme }:PS{ panel_set }{ targetpanel }")
    )) %>%
    dplyr::select(-scheme, -panel_set, -targetpanel) %>%
    tidyr::nest(
      scheme_ps_targetpanels = scheme_ps_targetpanel,
      scheme_ps_oldtargetpanels = scheme_ps_oldtargetpanel
    ) %>%
    dplyr::mutate(
      scheme_ps_targetpanels = purrr::map_chr(
        scheme_ps_targetpanels,
        spt_flattening_function
      ) %>%
        factor(),
      scheme_ps_oldtargetpanels = purrr::map_chr(
        scheme_ps_oldtargetpanels,
        \(df) {
          stringr::str_flatten(
            unique(df$scheme_ps_oldtargetpanel),
            collapse = " | "
          )
        }
      ) %>%
        factor()
    )

  .data %>%
    return()
}


#' concatenating and flattening stratum, grts join method, and scheme-ps-tp
concatenate_stratum_scheme_ps_targetpanels <- function(.data) {

  require_pkgs("dplyr")
  stopifnot("magrittr" = require("magrittr"))

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

  require_pkgs(c("stringr", "dplyr"))
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

    require_pkgs(c("dplyr", "purrr"))

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
extend_and_update_scheme_attributes <- function(.data) {

  require_pkgs(c("dplyr", "purrr", "stringr"))
  stopifnot("magrittr" = require("magrittr"))

  .data %>%
    dplyr::mutate(
      schemes_served_all = purrr::map_chr(scheme_moco_ps, function(df) {
        stringr::str_flatten(df$scheme %>% unique() %>% sort(), collapse = "|")
      }) %>%
        factor(),
      nr_schemes_current = purrr::map_int(scheme_moco_ps, function(df) {
        sum(df$is_current_occasion)
      }),
      nr_schemes_later = purrr::map_int(scheme_moco_ps, function(df) {
        sum(!df$is_current_occasion)
      }),
      scheme_moco_ps = purrr::map(scheme_moco_ps, function(df) {
        df %>%
          dplyr::filter(is_current_occasion) %>%
          dplyr::select(scheme, module_combo_code, panel_set)
      })
    ) %>%
    return()

}



#' Unite stratum, GRTS join method and scheme_ps_targetpanels columns
unite_stratum_and_schemepstargetpanels <- function(.data) {

  require_pkgs(c("dplyr", "stringr"))
  stopifnot("magrittr" = require("magrittr"))

  .data %>%
    dplyr::select(-scheme_ps_oldtargetpanels) %>%
    dplyr::mutate(
      stratum_scheme_ps_targetpanels = stringr::str_c(
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

  require_pkgs("dplyr")
  stopifnot("magrittr" = require("magrittr"))

  if (!exists("inner_join_m21_ed")) stop(
    "Please source the `repetitive_join_functions.R` script first."
  )

  .data %>%
    inner_join_m21_ed(
      n2khab_strata,
      dplyr::join_by(stratum)
    ) %>%
    dplyr::relocate(type, .after = stratum) %>%
    dplyr::select(-stratum) %>%
    return()
}



#' unnest schemes for which the FAG was originally planned in the current
#' date interval (is_current_occasion is TRUE), in order to add their
#' targetpanel attribute etc
unnest_and_join_sampling_unit_attributes <- function(.data) {

  require_pkgs(c("tidyr", "dplyr", "stringr"))
  stopifnot("magrittr" = require("magrittr"))
  if (!exists("inner_join_m21_ed")) stop(
    "Please source the `repetitive_join_functions.R` script first."
  )

  .data %>%
    tidyr::unnest(scheme_moco_ps) %>%
    # adding location attributes; using a left join since
    # fag_stratum_grts_calendar contains units adopted from old REP versions that
    # are not present in the sample objects (this can e.g. be checked using
    # count(., is.na(targetpanel)), count(., is.na(is_forest)) etc on the
    # intermediate result). Please note that this also means that those locations
    # (outside current sample) have missing values for several location
    # attributes. Note that this also adds the targetpanel attribute of the
    # current spatiotemporal sample to appended old FAG occasions that apply to
    # sampling units still present in the current spatial sample. This will be
    # reverted after joining the old targetpanel attribute (as
    # scheme_ps_oldtargetpanel) from cal_old_continuation, further below.
    left_join_m21_d(
      scheme_moco_ps_stratum_targetpanel_spsamples %>%
        dplyr::select(-is_aquatic) %>%
        # deduplicating 7220:
        dplyr::distinct(),
      dplyr::join_by(scheme, module_combo_code, panel_set, stratum, grts_address)
    ) %>%
    # restoring several of the location attributes from the phab-corrected base
    # sampling frame, since the extra units (outside current sample) don't have
    # them in scheme_moco_ps_stratum_targetpanel_spsamples
    dplyr::select(-starts_with("last_"), -grts_address_final) %>%
    add_assessment_data() %>%
    dplyr::select(-typelevel_certain) %>%
    dplyr::rename(
      last_type_assessment_in_field = assessed_in_field,
      last_type_assessment = assessment_date,
      last_inaccessible = inaccessible
    ) %>%
    # adding old targetpanel of the imported FAG occasions from old REP versions.
    # A part is dropped because of occasions that don't happen in the main year.
    left_join_121_d(
      cal_old_continuation %>%
        tidyr::unnest(scheme_moco_ps) %>%
        dplyr::mutate(
          scheme_ps_oldtargetpanel =
            stringr::str_c(scheme, ":PS", panel_set, targetpanel)
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
    dplyr::mutate(
      scheme_ps_oldtargetpanel = factor(scheme_ps_oldtargetpanel),
      # always set targetpanel values missing if the occasion is appended from an
      # older REP version (since for spatial units common with the current REP,
      # the targetpanel has been inherited from the the current REP, but this
      # should not be the case). Note that this ASSUMES that no FAG occasions are
      # common between the FAG calendar designed by the current REP, and the FAG
      # occasions that were appended from older REP versions!
      targetpanel = dplyr::replace_when(
        targetpanel,
        !is.na(scheme_ps_oldtargetpanel) ~ NA
      )
    ) %>%
    dplyr::relocate(targetpanel, .after = panel_set) %>%
    dplyr::relocate(grts_join_method, sample_support_code, .after = stratum) %>%
    dplyr::relocate(
      grts_address_final,
      domain_part,
      is_forest,
      in_mhq_samples,
      last_type_assessment_in_field,
      last_type_assessment,
      last_inaccessible,
      .after = grts_address
    ) %>%
    dplyr::relocate(scheme_ps_oldtargetpanel, .before = date_start) %>%
    dplyr::select(-module_combo_code) %>%
    return()

}


#' extract all `schemes` from the `scheme_ps_targetpanels` of a dataframe
#'
extract_and_flatten_scheme_from_scheme_ps_targetpanels <- function(.data) {

  if (!exists("require_pkgs")) stop("Please source the `system_helpers.R` script first.")
  require_pkgs(c("stringr", "dplyr", "purrr"))
  stopifnot("magrittr" = require("magrittr"))

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

} # /extract_and_flatten_scheme_from_scheme_ps_targetpanels
