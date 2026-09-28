---
aliases:
  - design
  - guidelines
---

TODO *cf.* [Codd's 12 rules](https://en.wikipedia.org/wiki/Codd%27s_12_rules)
in MNM context, additional guidance:
SQL syntax is preferred in ALL CAPS, e.g.
```sql
SELECT * FROM "inbound"."Visits" WHERE visit_done;
```

## Conventions (Incomplete List)

- Tables are capital/camel with plural `s`, e.g. `Activities`.
- Primary keys are singular, with suffix `_id` (*cf.* [[database/sequences and keys|primary keys]]).
- We do not mess with keys (`_id` columns); they are up for the database to handle (and may differ across databases).
- All relevant data must be identifiable by hard facts ([[glossary/characteristic columns|characteristic columns]]), such as a `grts_address`; if keys and sequences are lost or shuffled, we must find back our data.
- [[sql/views|Views]] do not get a prefix, because from query side it does not matter whether a table is a view or a real table.
- Always define an explicit accuracy for timestamp data types (e.g. `timestamp(0)` for seconds, `timestamp(3)` for milliseconds, *cf.* [[sql/sql queries on dates|queries on dates]]); otherwise implicit rounding at computer accuracy might lead to inaccurate units (e.g. `EXTRACT(milliseconds FROM log_creation)` -> `2464.999`).
- We embrace, but avoid [[sql/array data types|array data types]]. There should always be a conventional key link. Array types are a convenient way to handle a `n:1` link between tables, but reduce accessibility for users unfamiliar with the concept. Therefore, arrays should only be applied to fields which are relatively static, and which contain a low number (<20) of elements.
