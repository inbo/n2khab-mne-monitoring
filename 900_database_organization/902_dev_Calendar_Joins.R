library("tidyverse")


characteristic_columns <- c("grts_address", "stratum", "activity_group_id", "date_start")

data_pre <- readRDS("dumps/datelink_older.rds") # pre-update data, reactivated
# data_post <- readRDS("dumps/datelink_previous.rds")
data_post <- readRDS("dumps/datelink_future.rds")
# dfuture <- readRDS("dumps/datelink_future.rds")

# # NOT USED
# grts_selection <- c("122549",
#   "49896893", "21323197", "3554997", "29769397",
#   "51221550", "16470006", "120110", "23257",
#   "60185305", "1920534", "2136622", "1677870",
#   "53438326", "57632630", "437685", "8826293",
#   "24774", "1280278", "23238", "23091910",
#   "6314694", "4761777", "23238", "10119474",
#   "1202926", "10640110", "219694", "9525806",
#   "1999406", "6417454", "31496054", "219694"
# )


# filter_and_arrange <- function(.data) {
#   .data %>%
#     # filter(grts_address %in% grts_selection) %>%
#     filter(date_start >= as.Date("2025-07-01")) %>%
#     arrange(grts_address, stratum, activity_group_id, date_start) %>%
#     return()
# }
#
# dpre <- data_pre %>% filter_and_arrange()
# dpost <- data_post %>% filter_and_arrange()





#' Link dates of two calendar sets using common heuristics
#'
#' Links start dates from one set of calendar events to another
#' set of calendar events. Events are defined by unique lookup
#' columns (`characteristic_columns`). A difference in the date
#' column will be computed per characteristic observation, then
#' transformed (`dt_trafo`), and previous calendar entries will
#' be linked to those post-events by minimum date difference.
#' No event of the post-calendar can be used twice.
#' Note that this is no global optimization:
#'   events will be ordered (by group and date) and then
#'   associated "first come, first serve"; skips are not possible.
#'
#' @param data_pre data before change
#' @param data_post data after change
#' @param characteristic_columns a subset of columns common to the two
#'        data states by which old and new data can be uniquely identified and
#'        joined; may include the date column
#' @param date_column the name of the date column, defaults to `date_start`
#' @param dt_trafo transformation of time differences; examples in the
#'        nested functions below
#' @param date_threshold the "first ever" date to prohibit linking
#'        all-too-old data (specifically, events planned 2024 was never
#'        realized)
#' @param verbose provides extra prose on the way, in case you need it
#'
#' @examples
#' \dontrun{
#'   make_test_times <- function(t0, n, n_groups) {
#'     as.data.frame(t0 + sample.int(365, n * n_groups)) %>%
#'       setNames("date_start") %>%
#'       mutate(id = rep(seq_len(4), n)) %>%
#'       relocate(id)
#'   }
#'   test_pre <- make_test_times(as.Date(now()), 5, n_groups = 4)
#'   test_post <- make_test_times(as.Date(now()), 3, n_groups = 4)
#'
#'   link_dates(test_pre, test_post)
#' }
#'
link_dates <- function(
    data_pre,
    data_post,
    characteristic_columns = NULL,
    date_column = "date_start",
    dt_trafo = NULL,
    date_threshold = NULL,
    verbose = TRUE
  ) {

  stopifnot("dplyr" = require("dplyr"))
  stopifnot("lubridate" = require("lubridate"))

  ### time selection options
  # do not allow a shift backwards in time by further than a min_dt
  disable_backshift <- function(dt, min_dt = 0) {
    dt_pos <- dt
    dt_pos[dt_pos < min_dt] <- Inf
    return(dt_pos)
  }

  # disable past, based on minimum dt (diff from date to now)
  disable_past <- function(dt, min_dt) {
    dt_alltime <- dt
    dt_alltime[dt_alltime < min_dt] <- Inf
    return(dt_alltime)
  }

  # retain the order of events
  retain_event_sequence <- function(dt, pos = NA, nonmatch_disadvantage = 10) {
    if (is.na(pos)) {
      return(dt)
    }
    dt_seq <- dt

    idx <- seq_len(length(dt))

    # all lower-sequence events are impossible
    dt_seq[idx < pos] <- Inf

    # all future events are discouraged
    dt_seq[idx > pos] <- dt_seq[idx > pos] * nonmatch_disadvantage

    return(dt_seq)
  }

  # time difference transformation, to achieve various effects
  if (is.null(dt_trafo)) {
    dt_trafo <- function(dt, i = NA, min_dt = -Inf) {
      return(
        retain_event_sequence(
          abs(dt
            # disable_backshift(
            #   # disable_past(dt, min_dt),
            #   dt, min_dt)
          ), i
        )
      )
    }
  }


  # take all columns by default
  if (is.null(characteristic_columns)) {
    characteristic_columns <- names(data_pre)
  }
  
  ### time selection options
  if (is.null(date_threshold)) {
    date_threshold <- as.Date("2025-07-01")
  }

  # only char cols and date are relevant
  relevant_columns <- unique(c(characteristic_columns, date_column))

  # filter and sort data
  dpre <- data_pre[
      data_pre %>% pull(!!date_column) >= date_threshold,
    ] %>%
    dplyr::arrange(!!!rlang::syms(relevant_columns))
  dpost <- data_post[
      data_post %>% pull(!!date_column) >= date_threshold,
    ] %>%
    dplyr::arrange(!!!rlang::syms(relevant_columns))

  nondate_charcols <-
    characteristic_columns[characteristic_columns != date_column]

  dgroups <- dplyr::bind_rows(dpre, dpost) %>%
    dplyr::distinct(!!!rlang::syms(nondate_charcols)) %>%
    dplyr::arrange(!!!rlang::syms(nondate_charcols))

  if (verbose) {
    pb <- utils::txtProgressBar(
      min = 0, max = nrow(dgroups),
      initial = 0, style = 1
    )
  }

  ### groupwise comparison
  # row_nr <- 100
  compare_group <- function(row_nr) {

    if (verbose) setTxtProgressBar(pb, row_nr)

    grp <- dgroups %>%
      mutate(extraction_sequence_ = seq_len(n())) %>%
      filter(extraction_sequence_ == row_nr) %>%
      select(-extraction_sequence_)

    pre <- dpre %>%
      dplyr::semi_join(grp, by = dplyr::join_by(!!!nondate_charcols))
    post <- dpost %>%
      dplyr::semi_join(grp, by = dplyr::join_by(!!!nondate_charcols))

    pre[glue::glue("{date_column}_new")] <- as.Date(NA)
    pre <- pre %>% dplyr::mutate(
        # nearest_post = as.list(NA),
        dt_min = as.integer(NA)
      )

    # cross-difference dates
    date1 <- pre %>% dplyr::pull(!!date_column)
    date2 <- post %>% dplyr::pull(!!date_column)

    # has the original date already been passed?
    diff_today <- as.numeric(as.Date(lubridate::now()) - date1)
    diff_today[diff_today > 0] <- 0

    cross_dt <- outer(
      X = date1,
      Y = date2,
      FUN = function(X, Y) as.numeric(Y - X)
    )

    print(glue::glue("{row_nr} {nrow(cross_dt)}x{ncol(cross_dt)}"))

    # go rowwise # i <- 1
    for (i in seq_len(nrow(cross_dt))){
      row_dt <- cross_dt[i,]
      dtoday <- diff_today[[i]]

      # find minimum difference, after adjustments
      dt_transformed <- dt_trafo(row_dt, i, dtoday)
      min_dt_idx <- which.min(dt_transformed)

      # none acceptable
      if (is.null(dt_transformed)) next
      if (0 == length(dt_transformed)) next
      if (!is.finite(dt_transformed[[min_dt_idx]])) next

      # select correspondent entry
      dt_min <- row_dt[[min_dt_idx]]
      nearest_post <- post[min_dt_idx, ]
      date_start_new <- nearest_post[["date_start"]]

      # store info
      pre[i, "dt_min"] <- dt_min
      # pre$nearest_post[[i]] <- as.list(nearest_post)
      pre[i, glue::glue("{date_column}_new")] <- date_start_new

      # disable this correspondent
      cross_dt[i, min_dt_idx] <- Inf

    } # / loop pre rows

    pre %>%
      # dplyr::select(-nearest_post) %>%
      return()

  } # /compare_group

  dates_linked <- dplyr::bind_rows(lapply(
        seq_len(nrow(dgroups)),
        FUN = compare_group
    ))

  if (verbose) close(pb) # close the progress bar

  return(dates_linked)


} # /link_dates


make_test_times <- function(t0, n, n_groups) {
  as.data.frame(t0 + sample.int(365, n * n_groups)) %>%
    setNames("date_start") %>%
    mutate(id = rep(seq_len(4), n)) %>%
    relocate(id)
}
test_pre <- make_test_times(as.Date(now()), 5, n_groups = 4)
test_post <- make_test_times(as.Date(now()), 3, n_groups = 4)

link_dates(test_pre, test_post)

dates_connected <- link_dates(
  data_pre,
  data_post,
  characteristic_columns,
  date_threshold = as.Date("2025-07-01")
)

dates_connected %>% write.csv2("dumps/datelink_result.csv")


### inspection
## first iteration
# grts_to_find <- 327153 # ok
# grts_to_find <- 455349 # contains an ancient 9|GWLEVREADDIVERMAN
# grts_to_find <- 709330
# -> de-activated "no past" and "no backshift"
## second iteration
# grts_to_find <- 5705 # solved by dtoday !< 0
# grts_to_find <- 9262 # was set to 2024-01-01
# -> introduced minimum absolute date
## third iteration
# grts_to_find <- 53206450
grts_to_find <- 84598 # the double replacement; TODO separately tackled

dgroups %>% filter(grts_address == grts_to_find)
seq_len(nrow(dgroups))[dgroups$grts_address == grts_to_find]

fag_stratum_grts_calendar %>%
  filter(
    grts_address_final == grts_to_find,
    field_activity_group %in% c("GWINSTPIEZWELL", "SPATPOSITPIPE")
    # field_activity_group %in% c("GWINSTPIEZWELL", "GWLEVREADDIVERMAN", "SPATPOSITPIPE")
    ) %>%
    select(
      grts_address,
      stratum,
      field_activity_group,
      date_start
    )

fieldwork_shortterm_prioritization_by_stratum %>%
  filter(
    grts_address_final == grts_to_find,
    field_activity_group %in% c("GWINSTPIEZWELL", "SPATPOSITPIPE")
    ) %>%
    select(
      grts_address,
      stratum,
      field_activity_group,
      date_start
    )

data_pre %>%
  filter(
    grts_address == grts_to_find,
    activity_group_id %in% c(4, 9, 28)
  ) %>% arrange(activity_group_id, date_start)

data_post %>%
  filter(
    grts_address == grts_to_find,
    activity_group_id %in% c(4, 9, 28)
  ) %>% arrange(activity_group_id, date_start)

dpost %>%
  filter(
    grts_address == grts_to_find,
    activity_group_id %in% c(4, 28)
  )

dfuture %>%
  filter(
    grts_address == grts_to_find,
    activity_group_id %in% c(4, 28)
  )

dates_connected %>%
  filter(
    grts_address == grts_to_find,
    activity_group_id %in% c(4, 28)
  )

data_post %>% filter(grts_address == 5705)

# build a difference optimizer
# which incorporates distance from today (linearly)

# TODO there are many events still retained in STATUS QUO which are not planned any more.

# SUMMARY:
# - the basic procedure seems to work
# - jumps |dt| > 100d should be reported, but applied
# - planning status must be considered
