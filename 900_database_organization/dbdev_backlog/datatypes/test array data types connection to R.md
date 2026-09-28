---
aliases:
  - implement array data types in R database connection
tags:
  - arrays
  - datatypes
started: 2026-09-18
finished: 2026-09-22
execution: FM
status: true
priority:
---

introducing [[sql_tricks/array data types|array data types]] for [[implement optional and intrinsic matching occasions in all databases]]
testing locally whether R connection will handle them appropriately

(1) create a test table
```sql
CREATE SCHEMA playground;
GRANT ALL PRIVILEGES ON SCHEMA playground TO <user>;

```

```sql
DROP TABLE IF EXISTS playground.test;
CREATE TABLE playground.test (
    arr  int[],
    vector  int[][]
);

INSERT INTO playground.test (arr, vector)
VALUES
 ('{0, 0}', '{{0}, {0}}'),
 ('{1, 0}', '{{1}, {0}}'),
 ('{0, 1}', '{{0}, {1}}')
;
-- SELECT unnest(arr), UNNEST(vector) FROM playground.test;
```

(2) connect to database

```r
library("mnmdb")

test_auth <- mnmdbAuth(user = "guest", database = "sandbox")

mnmdb_connection <- mnmdbConnection(auth = test_auth)
mnmdb_connection <- mnmdb_connection |> connect()

```

(3) query test data
```r
test <- dplyr::tbl(mnmdb_connection@database_connection, DBI::Id("playground", "test"))
test2 <- test |> dplyr::collect()

## nothing works:
# test2 |> tidyr::unnest(vector)
# test2 |> mutate_at(vars(arr, vector), as.data.frame)
# test2 |> mutate_at(vars(arr, vector), as.numeric)
# test2 |> as.data.frame()
# test2 |> mutate(arr = unnest(arr))

```

```
> test2 |> glimpse()
Rows: 3
Columns: 2
$ arr    <pq__int4> {0,0}, {1,0}, {0,1}
$ vector <pq__int4> {{0},{0}}, {{1},{0}}, {{0},{1}}
```

### Finding a Workaround

```sh
git clone https://github.com/r-dbi/RPostgres
cd RPostgres

```

*(no hint)*

> Gemini is the new Google.
Used the chatbot to find any working solution.
It gave me five; only one worked.
It was less than ideal (`jsonlite` dependency), so I modified it (using `array_to_string` instead of `array_to_json`).

```r

requireNamespace("dbplyr", quietly = FALSE) # WTF?! "quietly" will suppress warnings...

data_uncollected <- dplyr::tbl(mnmdb_connection@database_connection, DBI::Id("playground", "test"))
array_columns <- c("arr", "vector") 

data_converted <- data_uncollected
for (col in array_columns) {
  data_converted <- data_converted %>%
    mutate_at(
      vars(tidyselect::all_of(c(col))),
      \(dcol) dbplyr::sql(sprintf("array_to_string(%s, ',', 'NULL')", col))
    )

}
data_collected <- data_converted %>% collect()


string_to_array <- \(arr_str) stringr::str_split(arr_str, pattern = ",")
string_array_to_int_array <- \(iarr) lapply(string_to_array(iarr), FUN = as.integer)

data_final <- data_collected %>%
  mutate_at(
    vars(tidyselect::all_of(array_columns)),
    string_array_to_int_array
  )

data_final %>% glimpse()

```

-> implemented to `MNMDatabaseConnection.R` [[timeline/2026-09-21|2026-09-21]]

### insert data

```r
# We should also be able to upload the data
data_upload <- data_final[1,]

data_upload[[1, "arr"]] <- list(c(1, 1))
data_upload[[1, "vector"]] <- list(c(1, 1))

# wrap_curls <- \(arr_str) paste0(c("ARRAY[", arr_str, "]"), collapse = "")
wrap_curls <- \(arr_str) paste0(c("{", arr_str, "}"), collapse = "")
listpaste <- \(arr) paste0(unlist(arr), collapse = ",")

# wrap_curls(listpaste(data_upload[[1, "arr"]]))
upload_prep <- \(x) wrap_curls(listpaste(x))
upload_2darr <- \(x) wrap_curls(listpaste(lapply(unlist(x), FUN = wrap_curls)))
# upload_2darr(data_upload[[1, "vector"]])

data_upload <- data_upload %>%
  mutate(
    arr = upload_prep(arr),
    vector = upload_2darr(vector)
  )

data_upload %>% glimpse()

rs <- DBI::dbWriteTable(
  mnmdb_connection@database_connection,
  DBI::Id("playground", "test"),
  data_upload,
  row.names = FALSE,
  overwrite = FALSE,
  append = TRUE,
  # binary = TRUE,
  # copy = FALSE,
  # field.types = c("arr" = "int[]", "vector" = "int[]")
  factorsAsCharacter = TRUE
)

# DELETE FROM "playground"."test" WHERE arr <@ '{1,1}';

```

-> implemented to `MNMDatabaseConnection.R` [[timeline/2026-09-22|2026-09-22]]

## Python

... handles this flawlessly.

```python
import sqlalchemy as SQL
from getpass import getpass
import pandas as PD

engine = SQL.create_engine(f"postgresql+psycopg2://guest:{getpass()}@127.0.0.1:5432/sandbox")

test = PD.read_sql_table("test", engine, schema = "playground")

print(test["arr"].apply(lambda arr: set(arr)))
```

(`set` is not meaningful, just used for test purposes.)
```
>>> print(test["arr"].apply(lambda arr: set(arr)))
0       {0}
1    {0, 1}
2    {0, 1}
Name: arr, dtype: object
```

(I have not attempted the INSERT direction)

```sh
# pip freeze
greenlet==3.5.6
numpy==2.5.3
pandas==3.0.6
psycopg2==2.9.13
python-dateutil==2.9.0.post0
six==1.17.0
SQLAlchemy==2.0.54
typing_extensions==4.16.0
```