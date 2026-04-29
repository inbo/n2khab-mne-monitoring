---
aliases:
  - copy testing
tags:
  - mirrors
---
One of the oldest desires of mankind is to copy.
Throughout our species' history, we copied the behavior of idols, music cassettes, or tictoc videos.
In this grand scheme of things, the invention of databases is relatively recent.

This summary describes how to copy the content of all, or only some, database tables from one database to another.
Some historic explanation can be found in `930_copy_database.org`, a compound file with code blocks which are extracted and stored to auxiliary files:
- `931_create_empty_testing.py`
- `932_production_to_testing_example.R`
- `933_populate_testing_db.R`

> [!note] Fill Testing Mirror
> The last of these scripts, `933_populate_testing_db.R`, is used to copy all database content from #production to #testing #mirrors.