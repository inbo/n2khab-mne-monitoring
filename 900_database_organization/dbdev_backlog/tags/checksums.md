---
aliases:
  - checksum
tags:
  - checksums
---
*(xxhash64 checksums of relevant #REP objects, assembled by #FV and used downstream for checking data consistency.)*

On the database side, checks are performed in several scripts; maybe most notably `401_snippet_selection.R`.
A file with the current checksums is kept in `/fieldworg_checksums.csv`.

Some possible reasons for changes:
- data changed
- order of columns in a data frame changed
- R version update ([[REP/fieldworg checksums changed unexpectedly]])