---
alias:
  - precedence
tags:
  - precedence_columns
---

*Precedence columns* are a subset of a table's columns which contain user-entered data, which grants them special protection from reset or removal operations.
Their neutral default values are known, and deviation from default marks table entries which are altered by users.

> [!warning] hard-coded
> Currently, there is no formal flag to filter or query precedence columns; their ever-growing list is clumsily maintained by a hard-coded list named `precedence_columns` in `MNMDatabaseToolbox.R`.