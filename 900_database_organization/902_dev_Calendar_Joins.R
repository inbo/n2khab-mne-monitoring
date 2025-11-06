library("tidyverse")

data_pre <- readRDS("dumps/datelink_older.rds")
# data_post <- readRDS("dumps/datelink_previous.rds")
data_post <- readRDS("dumps/datelink_future.rds")
# dfuture <- readRDS("dumps/datelink_future.rds")

# NOT USED
grts_selection <- c("122549",
  "49896893", "21323197", "3554997", "29769397",
  "51221550", "16470006", "120110", "23257",
  "60185305", "1920534", "2136622", "1677870",
  "53438326", "57632630", "437685", "8826293",
  "24774", "1280278", "23238", "23091910",
  "6314694", "4761777", "23238", "10119474",
  "1202926", "10640110", "219694", "9525806",
  "1999406", "6417454", "31496054", "219694"
)

characteristic_columns <- c("grts_address", "stratum", "activity_group_id")

filter_and_arrange <- function(.data) {
  .data %>%
    # filter(grts_address %in% grts_selection) %>%
    filter(date_start >= as.Date("2025-07-01")) %>%
    arrange(grts_address, stratum, activity_group_id, date_start) %>%
    return()
}

dpre <- data_pre %>% filter_and_arrange()
dpost <- data_post %>% filter_and_arrange()


dgroups <- bind_rows(dpre, dpost) %>%
  distinct(!!!rlang::syms(characteristic_columns)) %>%
  arrange(!!!rlang::syms(characteristic_columns))




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
keep_sequence <- function(dt, pos = NA, nonmatch_disadvantage = 10) {
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


### groupwise comparison

# row_nr <- 1
compare_group <- function(row_nr) {
  grp <- dgroups[row_nr,]

  pre <- dpre %>%
    dplyr::semi_join(grp, by = join_by(!!!characteristic_columns))
  post <- dpost %>%
    dplyr::semi_join(grp, by = join_by(!!!characteristic_columns))

  dt_trafo <- function(dt, i = NA, min_dt = -Inf) {
    return(
      keep_sequence(
        abs(
          dt
          # disable_backshift(
          #   # disable_past(dt, min_dt),
          #   dt,
          #   min_dt
          # )
        ),
        i
      )
    )
  }

  pre <- pre %>% dplyr::mutate(
      date_start_new = as.Date(NA),
      dt_min = as.integer(NA),
      nearest_post = as.list(NA)
    )



  # cross-difference dates
  date1 <- pre %>% dplyr::pull(date_start)
  date2 <- post %>% dplyr::pull(date_start)

  # has the original date already been passed?
  diff_today <- as.numeric(as.Date(now()) - date1)
  diff_today[diff_today > 0] <- 0

  cross_dt <- outer(X = date1, Y = date2, FUN = function(X, Y) as.numeric(Y - X) )

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
    # print(glue::glue("{dt_min} {date_start_new}"))
    pre[i, "dt_min"] <- dt_min
    pre$nearest_post[[i]] <- as.list(nearest_post)
    pre[i, "date_start_new"] <- date_start_new

    # disable this correspondent
    cross_dt[i, min_dt_idx] <- Inf

  } # / loop pre rows

  pre %>%
    dplyr::select(-nearest_post) %>%
    return()

} # /compare_group


dates_connected <- bind_rows(
  lapply(
    seq_len(nrow(dgroups)),
    FUN = compare_group
  )
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

fieldwork_2025_prioritization_by_stratum %>%
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
