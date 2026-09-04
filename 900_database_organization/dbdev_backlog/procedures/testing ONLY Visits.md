---
aliases:
tags:
  - inheritance
  - R
  - mirror
started: 2026-06-01
finished: 2026-06-01
execution:
  - FM
status: true
---

The `_testing` #mirror is filled with data by the script `933_populate_testing_db.R`.
Than script applies `mnmdb$query_table` and is therefore not inheritance-proof.


*... by the time I looked back at this, there has been a workaround to allow `ONLY`-like query_table calls with a keyword.*