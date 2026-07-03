---
tags:
  - schemes
  - schemes_served_all
  - SampleUnits
  - FieldCalendars
---
With the roll-out of #mnmsurfdb we first define #SampleUnits, #GroupedActivities and #Visits which **"serve" multiple schemes**.

However, it is not always trivial to associate which conceptual element serves which scheme at what time.

## Philosophy

**(i) Sample units** (defined by combination of type and GRTS address) are potentially (re-)used for multiple schemes; for example, a specific aquatic unit ("the puddle") can be part of either `SURF_03.4_lentic` or `GW_03.3` or both.

**(ii) Concrete field activities** (i.e. entries #FieldCalendars and #Visits) are **usually scheme-specific**; for example, groundwater work involves installing an observation well in the proximity of the puddle, whereas surface water fieldwork includes turbidity measurement and other splashy activities.
However, some field activities can serve **multiple schemes at once**; for example, a location evaluation #loceval will confirm the presence or absence of habitat types which might potentially be subject to both groundwater and surface water research.
**(iii) The general activity** of `LOCEVALAQ` (as defined in #GroupedActivities) can serve multiple schemes independent of location (i.e. on any given location).
Yet if a location is only drawn for one sampling scheme then **a specific activity** of type `LOCEVALAQ` in #FieldCalendars will serve that and only that scheme, until it is also drawn randomly for another scheme later on.

To summarize, *serving schemes* can be associated with multiple elements in our data hierarchy.
We can speak of SampleUnits, GroupedActivities, or Visits which specifically contribute to one or multiple given schemes.
For all of them, there is the abstract idea of "theoretically contributing" to our knowledge about a set of locations, and the practical idea of actual purpose ("which scheme caused / immediately benefits from planned locations or sequences of activities").


|                        | theoretical contribution     | actual measurement |
|:-----------------------|:----------------------------:|:------------------:|
| SampleUnits            |                              | !                  |
| GroupedActivities      |                              | n.a.               |
| FieldCalendars, Visits |                              | (planned/realized) |


## Database Implementation

Currently, practical purpose is well-captured in the #FieldCalendars of the different, separate databases ( #mnmgwdb, #mnmsurfdb): if an activity is planned in these calendars, it will most likely be in function of the associated schemes.
Location evaluations in #locevaldb will usually serve multiple / all schemes (though the database also holds scheme-specific activities, e.g. `SURFLENTSAMPLPOINT`); but because they are general, it is futile to record all schemes theoretically served.

> [!note] The databases only document `schemes_served_all` in #SampleUnits.

This field effectively contains all the consolidated schemes for all activities we hope to realize on that sample unit.
Content of `schemes_served_all` may be subject to change, e.g. if the sampling frame changes our plans or if an additional monitoring scheme is implemented.
The general association of a subset of activities to certain schemes can usually be recovered by considering sample unit and activity type; and the actual measurement is flagged by activities with `visit_done`.


