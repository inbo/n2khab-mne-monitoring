---
aliases:
tags:
  - FieldWork
  - QGIS
  - mnmgwdb
  - gemini
  - debugging
started: 2026-10-26
finished: 2026-10-26
execution:
  - FM
status: true
priority: 1
---

[[timeline/2026-10-26|2026-10-26]] There were persistent reports of prohibitive performance issues with the QGIS projects of `mnmgwdb`.

I could trace those back to the #FieldWork view which was not optimized for efficiency.
QGIS/QField do not query those efficiently, and repeated queries queue up on the host system to finally cause some inconveniently long lags.


> [!important] Summary
> This turned out to be an issue in the QGIS layer symbology.
> Depending on the set entered in the symbols list of map properties, 
> QGIS will construct a rather inefficient background query.
> In the present case, this slowed the map layer notably, no matter how efficient the underlying view was.


## step 0: identification
- We had upped server specs to counter this (one to multi cores, more RAM), but the problems persisted.
- Observing the server (with `top` and `systemctl status postgresql`) indicated peak loads which would staple.
- #QGIS: menu `View >> Panels >> Debugging/Development tools` have a "query logger" which indicated that there was a query returning ~900 rows which took multiple seconds; crucially, it was triggered multiple (2-3) times upon update.
- Screen recording by #WoS indicated that multiple, repeated requests queue on the server, amplifying a query response bottleneck which might otherwise be benign.

I suspected the #FieldWork #view (which is behind multiple map layers in QGIS and the most complex one in the project) and decided to attempt optimization.

## step 1: asking google Gemini
### prompt
#Gemini is available at our work environment (the "thinking" variant).

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
But even after fixing these broken references, the query had some filter conflicts and yielded zero rows.
This turned out to be an erroneous `ONLY` when querying `Visits` and joining other subtypes of visits; I suspect that the rather uncommon concept of table inheritance put the LLM under stress in this case.
I was tempted to continue with that query; however, the `WHERE` conditions selected very wrong calendar entries (i.e. only those with `visit_done`; must have been a slop of boolean operator from OR to AND).
However, the conceptual adjustments and general profiling insights from the LLM's answer are valuable.

I sincerely thank the AI overlords for providing an answer, will evaluate the suggested changes and come up with a solution which fixes the exposed flaws in my humble, human-written code.


### stacked `NATURAL FULL JOIN`s in the `VISIT` subquery

> * **Why it hurts:** Chaining four FULL OUTER JOIN operations creates a major optimization barrier. PostgreSQL cannot reorder FULL JOINs or push down outer WHERE predicates into them effectively. The engine is often forced to materialize and hash/merge all five visit tables completely before applying any filtering.  
> * **The NATURAL join risk:** NATURAL JOIN matches on **every** column with identical names across tables. If multiple visit tables share common administrative columns (e.g., notes, created\_at, archive\_version\_id, updated\_at), PostgreSQL will join on all of them simultaneously, likely corrupting the dataset and preventing index lookups.  
> * **Fix:** If "inbound"."Visits" is the parent table for all visit types, replace the full joins with explicit LEFT JOIN ... ON (or USING (visit\_id)).

Fully acknowledged, I did not consider the performance impact of the `NATURAL FULL JOIN`s.
I anticipate that this alone will shrink the query load to sub-threshold levels.

*edit: It turns out that this change, upon quick inspection, does not yield much performance improvement, unless coupled with totally wrong filters which erroneously reduce the resulting row set to a sub-trivial number.*


### Flawed and Costly Aggregation in `LOCEVAL`

>   Because eval\_date is included in the GROUP BY list, MAX(eval\_date) is evaluated per group, meaning MAX(eval\_date) is **always equal to eval\_date**. This does not actually isolate the single latest evaluation per sample unit. Instead, it performs an expensive aggregation (GROUP BY \+ DISTINCT) across the entire LocationEvaluations table.  
> * **Fix:** Use PostgreSQL's optimized DISTINCT ON clause:  

I previously thought that the `DISTINT ON` is just a syntax variant; I will read up on this and refactor.

*edit: It turned out that the LLM was wrong on this point. The suggested refactor just removed the search for the _latest_ loceval, instead falsely joining _all_ registered locevals. It turns out that this subquery and DISTINCT is no performance bottleneck at all.*

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

## Manual Refactoring - Lessons Learned

### Only Join by `id` Columns

This is slow and redundant:
```sql
  WHERE (VIS.visit_id = CAL.visit_id)
    AND (VIS.grts_address = CAL.grts_address)
    AND (VIS.stratum = CAL.stratum)
    AND (VIS.date_start = CAL.date_start)
    AND (VIS.activity_group_id = CAL.activity_group_id)
```

This is much quicker:
```sql
  WHERE (VIS.visit_id = CAL.visit_id)
```

> [!note] Joins
> Only use index columns for joins!
> (I know, I know: kids nowadays learn that in kindergarden.)

### Calendar & Visits combination

I decided to have an inner query with combined #FieldCalendars and #Visits.
Do not think it makes much of a difference, compared to `NATURAL FULL JOIN`, with the number of rows we handle.

### Join Types

switched to `INNER JOIN`, wherever possible


## The Actual Error
### QGIS Layer Symbology
It turned out that the actual error was one of #QGIS layer #symbology.

The last row in the following screenshot was initially missing:
![[attachments/qgis_layer_symbology_missing_others.webp]]

This caused QGIS to append the running query by a filtering row:

```sql
BEGIN READ ONLY;DECLARE qgis_764 BINARY CURSOR FOR
SELECT st_asbinary("wkb_geometry",'NDR'),
"visit_id",
"status"::text,
"teammember_assigned"::text,
"date_visit_planned"::text,
"days_to_visit"::text,
"activity_group_id"::text,
"date_visit"::text
FROM "inbound"."MyFieldWork"
WHERE (
  "wkb_geometry"
  && st_makeenvelope(12649.01449002728622872,153720.51358329199138097,260818.16945691470755264,244675.71358329200302251,31370))
AND
  ("status" IN ('GWINSTPIEZWELL','GWINSTPIEZWELL done','GWINSTPIEZWELL issues','SPATPOSITPIPE','SPATPOSITPIPE done','SPATPOSITPIPE issues','GWSHALLCLEAN','GWSHALLCLEAN done','GWSHALLCLEAN issues','GWSHALLSAMPREADMAN','GWSHALLSAMPREADMAN done','GWSHALLSAMPREADMAN issues','NULL'))
;

```

`status` uses the `text` data type, and filtering for values in this set is horribly inefficient.
Whats more, the list of categories was actually exhaustive: there were no `NULL` or other values, all actually used values were within that set.

### QGIS Query Debugging

Such errors can be found in the query profiler of the #QGIS #debugging panel "Debugging / Developer Tools".
That logger notes start and end times of queries (connected by a process id of the form `QGIS_123`).
Only visible layers are logged.
One can thereby find the limiting query and copy out the actual SQL for debugging.

![[attachments/qgis_query_debugging.webp]]
