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

- Tables are capital/camel with plural `s`, e.g. `Activities` (*exception:* `~Calendar`)
- primary keys are singular, with suffix `_id` (*cf.* [[database/sequences and keys|primary keys]]),
- [[sql/views|views]] do not get a prefix, because from query side it does not matter whether a table is a view or a real table
