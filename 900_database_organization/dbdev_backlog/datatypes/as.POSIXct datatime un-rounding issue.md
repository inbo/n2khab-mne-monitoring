---
aliases:
  - get millisecond timestamps for database upload
tags:
  - logging
  - timestamps
started: 2026-06-15
finished: 2026-06-15
execution:
  - FM
status: false
---

TODO status (20260615): waiting to see whether the switch to `character` logic crashes other scripts.


(*cf.* <https://stackoverflow.com/questions/79959088/lubridatefloor-date-returns-inaccurate-values-just-below-the-actual-roundin>, <https://stackoverflow.com/questions/7726034/how-r-formats-posixct-with-fractional-seconds>)

consequence of [[datatypes/applied date timestamp rounding to FreeFieldNotes log_creation on ALL servers and mirrors|applied timestamp rounding ...]]

> [!note] the LLM said:
> The displayed ...999 values are a formatting consequence of binary floating-point arithmetic, not necessarily evidence that `lubridate::floor_date()` failed to floor to the correct millisecond bucket.


implementation (base-r)
```r
#' convert a timestamp to a character string with millisecond accuracy
#'
#' @param ts a timestamp as.POSIXct
#' @return timestamp, in milliseconds, as.character
convert_timestamp_to_ms_character <- function(ts) {
  # timestamp string in seconds
  ts_char <- strftime(ts, format = "%Y-%m-%d %H:%M:%OS0")

  # milliseconds
  ts_ms_char <- as.character(floor(unclass(ts)*1000))
  l <- nchar(ts_ms_char)
  ms <- substr(ts_ms_char, start = l-2, stop = l)

  # timezone
  tz <- format(ts, format = "%Z")

  return(paste0(c(ts_char, ".", ms, " ", tz), collapse = ""))
} # /convert_timestamp_to_ms_character

# testing
convert_timestamp_to_ms_character(as.POSIXct("1970-01-01 12:00:00.000", tz = "Europe/London"))
convert_timestamp_to_ms_character(as.POSIXct("1970-01-01 12:00:00.001", tz = "Europe/London"))
convert_timestamp_to_ms_character(as.POSIXct("1970-01-01 12:00:00.002", tz = "Europe/London"))
convert_timestamp_to_ms_character(as.POSIXct("1970-01-01 12:00:00.999999", tz = "Europe/London"))
for (i in seq_len(100)) {
  print(convert_timestamp_to_ms_character(Sys.time()))
}
```

## Observation

attempt to replace all `as.POSIXct(Sys.time())` with `as.POSIXct(lubridate::floor_date(Sys.time(), unit = ".001s"))` -> 
checked with
```r
> format(as.POSIXct(lubridate::floor_date(Sys.time(), unit = ".001s")), format = "%Y-%m-%d %H:%M:%OS6")
[1] "2026-06-15 11:03:13.542999"
> format(lubridate::floor_date(Sys.time(), unit = ".001s"), format = "%Y-%m-%d %H:%M:%OS6")
[1] "2026-06-15 11:05:37.780999"
```

args, it un-rounds!

```r
options(digits.secs=7)
for (i in seq_len(100)) {
  print(lubridate::floor_date(Sys.time(), unit = ".001s") + lubridate::seconds(0.00001))
  # print(format(lubridate::floor_date(Sys.time(), unit = ".001s"), format = "%Y-%m-%d %H:%M:%OS6"))
}
```

further attempts:
```r
# options(digits.secs=3)
options(digits.secs=7)
for (i in seq_len(100)) {
  print(lubridate::round_date(
    lubridate::floor_date(Sys.time(), unit = ".001s"),
    unit = ".001s"
  )
  )
  # print(lubridate::floor_date(Sys.time(), unit = ".001s"))
  # print(lubridate::floor_date(Sys.time(), unit = ".001s") + lubridate::seconds(0.00001))
  # print(format(lubridate::floor_date(Sys.time(), unit = ".001s"), format = "%Y-%m-%d %H:%M:%OS6"))
}

```

In fact, this would do it:

```r
options(digits.secs=7)
for (i in seq_len(100)) {
  t <- strftime(Sys.time(), format = "%Y-%m-%d %H:%M:%OS4")
  print(stringr::str_sub(t, end = -2))
}
```
However, then I leave the safe territory of date/timestamp datatypes.

## switch defaults
[[timeline/2026-06-18|2026-06-18]] changed default data type to "character" (i.e. `string`).
useful tricks:

```r
  DBI::dbWriteTable(
    mnmdb$connection,
    name = srctab,
    value = <news>,
    overwrite = TRUE,
    temporary = TRUE,
    field.types = c("log_creation" = "timestamp(3)") # !!!
  )
```
