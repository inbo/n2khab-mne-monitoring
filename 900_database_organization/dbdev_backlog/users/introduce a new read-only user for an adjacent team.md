---
aliases:
tags:
  - users
  - roles
started: 2026-06-16
finished: 2026-06-16
execution:
  - FM
status: true
---
via `postgres` user:

```
CREATE USER <guest> WITH ENCRYPTED PASSWORD 'abc123';
GRANT viewer_mnmdb TO <guest>;
```

add [[locations/pg_hba|pg_hba]] entry


## usage

(1) via terminal
![[attachments/sql_terminal_connection_20260616.jpg]]

(2) via sql management program (e.g. [dbeaver](https://dbeaver.io)):
![[attachments/sql_dbeaver_connection_20260616.jpg]]
![[attachments/sql_dbeaver_query_example_20260616.jpg]]

(3) via R - raw code
![[attachments/sql_r_console_20260616.jpg]]

(4) via R - toolbox
best established with direct support
https://github.com/inbo/n2khab-mne-monitoring/blob/main/990_database_documentation/R/R%20database%20connection%20usage%20example.md
cf. [connection config file](https://github.com/inbo/n2khab-mne-monitoring/blob/main/990_database_documentation/usage/connection%20config%20file.md)

(5) QGIS
via `Layer` >>> `Data Source Manager` (`[Ctrl]+[L]`)
connection parameters as above
specific View necessary (geo-information is in a separate table) -> on request