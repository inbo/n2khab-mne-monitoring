---
aliases:
tags:
started:
finished:
execution:
status: false
---


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