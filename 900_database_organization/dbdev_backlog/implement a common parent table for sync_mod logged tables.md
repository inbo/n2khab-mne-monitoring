---
aliases:
  - sync_mod inheritance
  - introduce LoggedTables
tags:
  - inheritance
  - sync_mod
  - trigger
  - function
  - LoggedTables
started:
finished:
execution:
status: false
---

Currently, the `sync_mod` function is applied *ex post* to a variety of tables.
Its purpose is to log update times and users.

> [!note] condition on user
> ex-Limitation: the function can now distinguish based on user type.
> Technical modifications are not logged, rather store only real user interventions.


Instead of applying the function to many different tables, these tables could each inherit an interface with the logging columns.
An advantage would be that we also get a central list with changes.
The name might be #LoggedTables.
