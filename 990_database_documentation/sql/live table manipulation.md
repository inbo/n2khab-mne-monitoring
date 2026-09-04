---
aliases:
  - changing the structure of database tables on the fly
  - non-invasive database tinkering
tags:
  - database
  - structure
  - example
---

*Herein, I assemble some good practices when changing a database while it is actively used.*


Not all database modification action groups (DMAG's) are as straight forward as [[maintenance/add column|appending a column]].

Options to ensure no data is lost are:

- #views with the same name as the old table name which map the new table
- [[sql/update rules|update rules]] which write table to the new logic if the old table gets updated (can be bi-directional)
- keep old columns, regularly update new columns from novel entries in the old field, and only delete them after roll-out and safety period (mind people's vacations)

Generally, #views are easier to maintain than direct table connections: 
names can be aliased to ensure continuity (at least until the next major change gets released).