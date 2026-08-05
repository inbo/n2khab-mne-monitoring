---
aliases:
  - schemas and their purpose
tags:
  - schema
---

Though this is not a strict requirement, we organize databases in [schemas](https://www.postgresql.org/docs/current/ddl-schemas.html).

> [!warning] Disambiguation
> In context of the #MNE project and the [[glossary/revisit plan|REP]], we use the term [[glossary/scheme|scheme]].
> Do not confuse them with database `schema` (this page).

Schema's in SQL define groups of tables or #views which may have shared purpose or shared user [[database/userroles|permissions]].
For all practical purposes, schema's which are not the default schema (`public`) force SQL programmers to add an extra prefix to the table ID (e.g. to access the #Visits it is insufficient to just query that name; instead, one must address `"inbound"."Visits"`).

We use schema's as a loose collection of table purpose.

| schema  | purpose |
|---|---|
|metadata| tables with rather static background information |
|outbound| tables which have values entered from the REP or by planners, providing information for fieldwork |
|inbound| data input tables |
|transfer| synchronization between databases |
|analysis| *(future)* tables which only serve analytical purpose and not fieldwork |
|archive| storage of information which may not be lost |
