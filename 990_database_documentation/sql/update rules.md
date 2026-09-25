---
aliases:
  - rules
  - insert rules
tags:
  - updaterules
  - rules
---
In the context of [[server/postgresql|postgresql]], #rules are functions or sets of instructions which are executed whenever certain [[sql/query|query]] is sent to the database.
There are default rules, and those are usually not recognized by end users: for example whenever an `UPDATE` query hits a table, all the provided info in the requested columns is permanently changed in server memory.

However, one can override the default rules and define one's own weird set of instructions.

Basic syntax is:
```sql
CREATE RULE <label> AS
  ON UPDATE TO <table or view>
DO INSTEAD <action>
;

CREATE RULE <label> AS
  ON INSERT TO <table or view>
  WHERE <condition>
DO ALSO <action>
;

```

> [!note] Actions
> Note that `UPDATE` and `INSERT` are also actions on the focal table or view, which then trigger different actions, potentially on other tables.


> [!warning] CREATE OR REPLACE
> Although it is technically possible to use `CREATE OR REPLACE` syntax for rule definition, this will cause issues and crash if the view is altered afterwards. 
> Therefore, it seems best to always `DROP RULE IF EXISTS <label> ON <table>;` prior to `CREATE RULE`.