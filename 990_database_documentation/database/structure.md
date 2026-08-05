---
aliases:
  - database structure
tags:
  - database
  - structure
  - tables
  - schemas
---
*work in progress -- always*

# General Structure

The central concepts of the #REP have correspondence in the structure of the #MNE databases.

- **Sample Units** -> link to metadata
- **Calendar** -> link to REP
- **Visits** -> interaction with fieldwork, but coupled to Calendar and REP
- **Observations** -> extra / explanatory information; optionally coupled to Visits but can be spatially/temporally independent

An overview of the general database structure:

![[attachments/mnmdb_general_structure.svg]]

- A number of `metadata` tables flank and enrich the central database tables.
- tables are assigned to [[database/schema|schemas]] (not shown)
- [[database/generation|generation]] happens via structure sheets and scripts
- an incomplete, probably outdated overview of all [[tables/tables|tables]] is unmaintained in another subfolder of these docs


More details can be found in these notes:
+ [[database/design guidelines|design guidelines]]
+ [[database/Visits Observations and FreeFieldNotes]]
+ [[sql/optional link of Observations and Visits|optional link of Observations and Visits]]


### Obsolete: pgmodeler structure overview ("reverse engineering")
... can be viewed with ~~[pgmodeler](https://pgmodeler.io)~~
*edit: pgmodeler  [went commercial](https://www.pgmodeler.io/blog/2026/5/13/the-future-of-pgmodeler-project#comment-panel) in May 2026; I inquired about a GPL license violation with GNU and FSF but, (1) GPL does not exclude monetization and (2) they will not take action because it seems that feature regression is a greyzone.*
