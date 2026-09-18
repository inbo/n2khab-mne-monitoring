---
aliases:
tags:
started:
finished:
execution:
status: false
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