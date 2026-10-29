---
aliases:
  - optional matches
  - intrinsic matches
tags:
  - matchingoccasions
---

> [!note] Definition [[glossary/revisit plan|REP]]
> The same [[glossary/FAGs|FAG]] that appears repeatedly in #FieldCalendars for different *aquatic* types but at the same location (GRTS address) and date range is marked as `matching_occasion` (column in the short-term fieldwork calendar).
>  - A “matching_occasion” effectively refers to a single group of activities in the field, since different sampling units are represented by the same body of water: multiple aquatic types may occur at the same locations.
>  - This occurs in #mnmgwdb (groundwater) and #mnmsurfdb (surface water) monitoring networks.
>  - It is possible (e.g., LOCEVALAQ) that data collection is specific to each sampling unit, but it is carried out all at once for the different types.
>  - For observation well installation, diver readings, and surveying, the requirement for equal time intervals does not apply, since these occur only once per sampling unit in the short-term calendar (their first occurrence).
>  *( #FV, "REP 0.17.0 is uit", 2026-07-03)*
>  - In addition, data collection events for primary target variables can serve multiple sample units at the same instance.


The concept of matching on the levels of #FieldCalendars and/or #Visits required some thorough considerations.
 There must be a distinction between "**optional matches**" (to prepone future auxiliary FAGs for efficiency) and "**intrinsic matches**" (same primary FAG on same date for different Sample Units).

## Optional Matching Occasions ( #OMOs )
The purpose of "optional matching" is to display future activities at a site to enable the choice of *preponing a future activity*, thereby avoiding double visits and saving efforts in the long term.
This usually applies to *auxiliary FAGs*, and is purely for display purposes: the (future, co-located) activities are independent of the present ones which trigger the preponement, and each require their own series of steps to be carried out and field forms to be filled.

Examples: 
- #loceval Locations Evaluation: the same location may enter different monitoring schemes, getting revisit-scheduled at different time points. Since location evaluation must precede main [[glossary/FAGs|FAGs]], but has a finite validity, the location evaluation for a type which is scheduled later can often be executed on the earlier visit to the same location.
- #InstallationVisits Observation Well Installations: though these are *intrinsical matches* by nature (see below), we might prefer to convert a scheduled installation at an existing location into a revisit for inspection and maintenance of the installation. Leaving the match as "optional" helps to keep our field apps open for either decision.

We implemented this by simply adding extra information from the REP to #FieldCalendars:
- There is a text group in #FieldCalendars, storing the `matching_occasion` (received directly from the #REP).
- The earliest date of a set of matching occasions is `date_suggested`; it takes precedence over `date_start` for scheduling fieldwork. However, `date_start` remains the more important, characteristic column.

## Intrinsic Matching Occasions ( #IMOs )
If the [[glossary/revisit plan|REP]] schedules simultaneous #Visits for different #SampleUnits at the same #Locations, those would normally require individual field forms to be filled.
However, if the #FAG is *identical* for those units (same location, same revisit schedule, i.e. we only go once), then that pseudo-replication would cause unnecessary efforts by field personnel, not to mention issues of potentially inconsistent entry.
Practically, whenever exactly the same field activity is serving data for two scheduled occasions for two units (they really co-incide), we consider them *intrinsically* linked.

Therefore, scheduled matching activities must be merged on the level of #Visits.
To guarantee consistency with the REP, the #FieldCalendars will remain separate; after all, it could theoretically be planned to perform the visit for only one of multiple simultaneous occasions (e.g. if loceval was negative for either of the co-incident habitat types).
However, on the level of visits, a single visit may be linked to multiple entries in the `FieldCalendars`.

We implemented this practically ( #FM, 2026-09-24) by the following adjustments to our [[database/structure|database structure]]:
- #FieldCalendars and #Visits are now linked by `visit_id` (`n:1` relation). 
- Previously, `fieldcalendar_id` was the linking foreign key; it is kept as an [[sql/array data types|array field]] (`fieldcalendar_ids`) for convenience.
- #Visits have `stratums` as a [[glossary/characteristic columns|characteristic column]] with an array type: one visit can potentially serve multiple strata; the strange grammar (`stratums` instead of `strata`) was chosen to keep the unusual plural-`s` as a unifying element to distinguish array fields.
- From multiple `stratums` follow multiple #SampleUnits, linked in #Visits via `sampleunit_ids`. 
- There is a text group in #FieldCalendars, storing the `matching_occasion` (received directly from the #REP).
- The earliest date of a set of matching occasions is `date_suggested`; it takes precedence over `date_start` for scheduling fieldwork. However, `date_start` remains the more important, characteristic column.
- #Views facilitate grouping and *ad-hoc* un-grouping of calendars and visits, or their link via an id tree: #MatchingOccasions, #VisitsUnnested, and  #FieldCalendarsAggregated.

For consistency, these changes where also partly applied to databases where no intrinsic matches are present (yet).