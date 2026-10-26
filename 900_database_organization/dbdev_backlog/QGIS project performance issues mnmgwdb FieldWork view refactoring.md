---
aliases:
tags:
  - FieldWork
  - QGIS
  - mnmgwdb
  - gemini
started:
finished:
execution:
status: false
priority:
---

[[timeline/2026-10-26|2026-10-26]] There were persistent reports of prohibitive performance issues with the QGIS projects of `mnmgwdb`.

I could trace those back to the #FieldWork view which was not optimized for efficiency.
QGIS/QField do not query those efficiently, and repeated queries queue up on the host system to finally cause some inconveniently long lags.


## step 0: identification
- We had upped server specs to counter this (one to multi cores, more RAM), but the problems persisted.
- Observing the server (with `top` and `systemctl status postgresql`) indicated peak loads which would staple.
- #QGIS: menu `View >> Panels >> Debugging/Development tools` have a "query logger" which indicated that there was a query returning ~900 rows which took multiple seconds; crucially, it was triggered multiple (2-3) times upon update.
- Screen recording by #WoS indicated that multiple, repeated requests queue on the server, amplifying a query response bottleneck which might otherwise be benign.

I suspected the #FieldWork #view (which is behind multiple map layers in QGIS and the most complex one in the project) and decided to attempt optimization.

## step 1: asking google Gemini
### prompt
#Gemini is available at our work environment.
I submitted the request to 
```
Evaluate the following postgreSQL query for performance: 
[...]
Which could be potential bottlenecks for performance, and how could I optimize the query structure to achieve better performance? (e.g. by nesting or unnesting parts)
```

The LLM gave some useful hints at potential performance breakers:
+ stacked `NATURAL FULL JOIN`s in the `VISIT` subquery
+ Flawed and Costly Aggregation in `LOCEVAL`
+ Accidental Inner Joins Masquerading as `LEFT JOIN`s
+ Unnecessary Subquery Wrappers
+ Boolean Redundancies in WHERE and SELECT

The LLM also provided a refactored query, which was broken due to missing context (it did not know which columns came from which tables, particularly for `*Visits`).

I sincerely thank the AI overlords for providing this answer, will evaluate the suggested changes and come up with a solution which fixes the exposed flaws in my humble, human-written code.

### stacked `NATURAL FULL JOIN`s in the `VISIT` subquery

> * **Why it hurts:** Chaining four FULL OUTER JOIN operations creates a major optimization barrier. PostgreSQL cannot reorder FULL JOINs or push down outer WHERE predicates into them effectively. The engine is often forced to materialize and hash/merge all five visit tables completely before applying any filtering.  
> * **The NATURAL join risk:** NATURAL JOIN matches on **every** column with identical names across tables. If multiple visit tables share common administrative columns (e.g., notes, created\_at, archive\_version\_id, updated\_at), PostgreSQL will join on all of them simultaneously, likely corrupting the dataset and preventing index lookups.  
> * **Fix:** If "inbound"."Visits" is the parent table for all visit types, replace the full joins with explicit LEFT JOIN ... ON (or USING (visit\_id)).

Fully acknowledged, I did not consider the performance impact of the `NATURAL FULL JOIN`s.
I anticipate that this alone will shrink the query load to sub-threshold levels.

### Flawed and Costly Aggregation in `LOCEVAL`

>   Because eval\_date is included in the GROUP BY list, MAX(eval\_date) is evaluated per group, meaning MAX(eval\_date) is **always equal to eval\_date**. This does not actually isolate the single latest evaluation per sample unit. Instead, it performs an expensive aggregation (GROUP BY \+ DISTINCT) across the entire LocationEvaluations table.  
> * **Fix:** Use PostgreSQL's optimized DISTINCT ON clause:  

I previously thought that the `DISTINT ON` is just a syntax variant; I will read up on this and refactor.

### Accidental Inner Joins Masquerading as `LEFT JOIN`s

> * **Why it hurts:** CAL and ACT are declared with LEFT JOIN, but the WHERE clause strictly filters them:  
  * (CAL.is\_scheduled OR CAL.done\_planning)  
  * (NOT CAL.excluded)  
  * (ACT.activity\_group IS NOT NULL)
> Any row where CAL or ACT produces NULL values is eliminated by the WHERE filter.
> * **Fix:** Explicitly define them as INNER JOINs. This signals to the planner that rows without matching calendar or activity records can be dropped immediately, allowing PostgreSQL to use CAL (which usually has strong filtering) as the driving table.

Yes, and no. 
It makes sense to think about `INNER JOIN`s in these cases, given the filtering.
I will have to double check whether switching to #FieldCalendars as a primary table for this query is possible.


### Unnecessary Subquery Wrappers

> * **Why it hurts:** SOIL, ACT, and CAL are wrapped in subqueries that simply select columns or inline basic CASE statements. While the PostgreSQL optimizer can often flatten simple subqueries, keeping them inlined adds parsing overhead, obscures column statistics, and makes queries harder to maintain.  
> * **Fix:** Join the underlying tables directly and move computed columns to the main SELECT or WHERE clause.

I anticipate a minor performance impact, at the cost of readability and maintainability (at least for me) of the complex query, but will attempt this.


### Boolean Redundancies in WHERE and SELECT

> * CAL.is\_scheduled is defined as: CASE WHEN (date\_visit\_planned IS NULL) THEN FALSE ELSE done\_planning \= TRUE END  
> * The WHERE condition tests (CAL.is\_scheduled OR CAL.done\_planning). If done\_planning is true, the condition is satisfied; if done\_planning is false/null, is\_scheduled can never be true. Thus, (CAL.is\_scheduled OR CAL.done\_planning) simplifies directly to: CAL.done\_planning \= TRUE

This is a detail.

## Manual Refactoring

