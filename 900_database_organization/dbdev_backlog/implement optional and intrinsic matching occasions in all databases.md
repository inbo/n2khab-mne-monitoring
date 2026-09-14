---
aliases:
tags:
  - matching_occasions
  - FieldCalendars
started:
finished:
execution:
status: false
priority:
---

*supersedes [[implement matching occasions for locevals]]*

> [!warning] Concept and Design
> The concept of matching on the levels of #FieldCalendars and/or #Visits required some thorough considerations.
> The main issues are:
> 1. There must be a distinction between "**optional matches**" (to prepone future auxiliary FAGs for efficiency) and "**intrinsic matches**" (same FAG on same date for different Sample Units).
>  2. For intrinsic matches, we will switch to an `n : 1` linkage between FieldCalendars and Visits, thereby deviating from the historic, robust `1:1` linkage they were initiated with (which requires the use of array columns, and careful handling of existing data).
>  3. Views and QGIS field forms on these tables are complex. Although a view-side grouping of e.g. intrinsic matches might be feasible, this would further complicate things and hinder maintenance while at the same time producing data redundancy.
>  4. The distinction of whether an activity group is optionally or intrinsically linkable depends on whether it is an auxiliary FAG. However, mnmgwdb's InstallationVisits would justify *intrinsic* grouping across time, but it will be represented as *optional* for now (reason: we might decide to pass by for an "installation refreshment".
>  5. Speaking of... there are different `*Visits` and thereby many tables | views | map layers which can be affected.

## Optional Matches for #locevaldb 

prepare the minimum required columns

```sql
ALTER TABLE "outbound"."FieldCalendars" ADD COLUMN matching_occasion varchar; 
COMMENT ON COLUMN "outbound"."FieldCalendars".matching_occasion IS E'group label of actifity groups which may be combined (optional match)';

ALTER TABLE "outbound"."FieldCalendars" ADD COLUMN date_suggested date; 
COMMENT ON COLUMN "outbound"."FieldCalendars".date_suggested IS E'earliest date of activities in an optional matching group';

```