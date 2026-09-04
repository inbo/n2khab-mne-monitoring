---
aliases:
  - MNMDatabaseToolbox
  - DatabaseToolbox
tags: 
  - FP
---
the "toolbox" is a code assembly of more- or less generic **procedures** which are used to work with the MNM data

## precedence columns
`precedence_columns` are a *hardcoded list* of database fields which hold user input.
If those columns are changed, an entry is fixed and will not be auto-deleted (user input takes precedence over planning changes).
There is a task to replace these with more dynamic database field classification (as soon as possible).