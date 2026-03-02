# MNM Database Organization

This folder collects organizational procedures, scripts, and documentation, in context of the database installments of the MNE project.

Further documentation about the database is available in the adjacent subfolder, `/990_database_documentation`.

The folder uses file numbering to impose some structure on the many database-related tasks.
This was chosen in favor of subfolders because the scripts and quarto notebooks interact heavily.

- `0*` -> documentation and dashboarding
- `1*` -> maintenance scripts (for daily use)
- `2*` -> general structure and procedures
- `3*` -> *reserved* for a future database storing central info (tbd.)
- `4*` -> connection to upstream data sources
- `5*`-`8*` -> database-specific procedures
- `9*` -> helper scripts and ad-hoc work

General tooling is found directly on this folder (e.g. a database connection object in `MNMDatabaseConnection.R`).


# History

|---------:|:--------------------------|
| `202603` | initial merge of `dbinit` |

