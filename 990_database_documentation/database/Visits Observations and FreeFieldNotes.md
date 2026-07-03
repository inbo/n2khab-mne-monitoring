---
tags:
  - Visits
  - Observations
  - FreeFieldNotes
aliases:
  - Visits, Observations, and FreeFieldNotes
---
We define several general types of tables for capturing data during fieldwork ("inbound"). 
They differ in terms of their spatiotemporal coupling to the #REP calendar ("strict", "loose", or "none"). 
For practical reasons, #Visits and #Observations are implemented via [[sql/inheritance|inheritance]] as an [[glossary/interface|interface]] for other, more specific data input tables.
## `*`Visits: 
#Visits, in the context of our database, is just another term for "field activity group" ([[glossary/FAGs]]).
However, the term "Visit" implies a more fieldwork-centered perspective, in the sense that the table captures the actual information gathered in actual visits to locations of interest.

Visits are *strictly* bound to the #REP: they are coupled to #FieldCalendars in a 1:1 relation.
For the most critical activity groups, there may be no visits without REP indication.

## `*`Observations:
Observations were introduced during the initialization of #mnmsurfdb. 
The tables which implement the #Observations interface are *loosely* linked to the REP and also coupled during the REP-induced field visits.
However, the actual link happens via spatiotemporal proximity instead of database matching.

This provides extra freedom during field research to react to 
1. **temporal requirements** of (side-)tasks: some long-term information does not have to be collected on every visit. An example are hydrogeographical morphology of waterbodies which are collected once and only updated upon major changes.
2. **spatial requirements:** whereas `*Visits` are inseparably linked to the #Locations via #SampleUnits, observations often occur in the vicinity of those target locations where it makes more sense to provide their own exact GIS info. For example, industrial landuse close to a sample unit can be flagged as `LanduseObservations`; their exact location is recorded to allow for distance thresholds later on.

## FreeFieldNotes
#FreeFieldNotes are free notes on any location which are completely independent of the REP (although of course they facilitate REP-related work).