---
alias:
  - characols
tags:
  - characteristic_columns
---

*Characteristic columns* are a subset of a table's columns which is sufficient to uniquely identify each entry.
They can be (and sometimes are) hard-constrained as `UNIQUE` identifiers.

- Characteristic columns should never `UPDATE` or change.
- As opposed to [[database/index columns|index columns]], they are stable and preserve the identity of an entry even across major structural changes.
- They are not hard-linked to avoid issues of cascading and auto-increments.

> [!warning] Not Formalized
> Currently, characteristic columns are not hard-wired: they are conceptually chosen per table, found as character vectors in our R scripts, but there is no flag identifying them.

For example, the characteristic columns across our central #FieldCalendar - #Visits paradigm are `grts_address`, `type`, `date_start`, and `activity_group_id`.
Their specificity is incremental: whereas `grts_address` is sufficient to identify #Locations, `type` is an additional requirement to define #SampleUnits, and so forth.