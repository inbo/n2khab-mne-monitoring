---
aliases:
tags:
  - Observations
  - Visits
  - updaterules
  - mnmsurfdb
---

> [!note] In a Nutshell
> - #Observations are optionally linked to #Visits by the columns `teammember_id`, `date_visit` and `grts_address`.
> - Conversely, Visits contain booleans (one per category) to flag the ones that *should* also have associated observations.
> - "Optionally" means that Observations can also exist independent of any Visits and unrelated to the [[glossary/GRTS address|GRTS]] raster.
> - The field `inbound.Observations.visit_id` is a shortcut for quick linking, a "soft foreign key", kept consistent by script.
> - [[sql/update rules|Update rules]] ensure that features are (lazily) created in the Observations tables with all the linking columns set correctly, or that existing associated Observations get updated.


## Terminology and Definitions

One core purpose of [[glossary/revisit plan|revisit planning]] is to receive a temporally balanced **calendar** of [[glossary/FAGs|field activities and field activity groups]] (FAGs) to be executed on a spatially balanced subset of [[glossary/sample unit|sample units]].

That calendar must be strictly followed, and the planned FAGs realized by fieldwork visits. 
This is reflected in the tables #FieldCalendars and #Visits, which are central to the REP-related component of the [[database/structure|database structure]].

#Visits are thus defined by the REP and may not be changed by users in space and time.
However, during fieldwork, there can be relevant #Observations made on a different place or at a different time than those fixed by the calendar (see [[database/Visits Observations and FreeFieldNotes|Visits, Observations, and FreeFieldNotes]]).


> [!tip] Create Linked Observations in QField
> ![[attachments/qfield_create_linked_Observations.webp|640]]
> When entering data for #Visits in the QField map layer which links to the #FieldWork view,
> the tab "omgevingsdata" (left panel) provides selection of different Observation classes (which appear in tabs upon toggling the switch).
> In that tab (right panel), the input fields of an observation table are made available.

Of course, we would like to capture such information in a structured way.
And for some field visits, we even make the active investigation for some typical classes of observations mandatory (e.g. perturbations, sample context, and meteorology on #mnmsurfdb work).

> [!important] Linking Observations to Visits
> In cases where #Observations are derived in the context of (and therefore linked to) #Visits, 
> the field forms must automatically create and link observations to the visit.
> The fields which can be used to join both tables are `teammember_id`, `date_visit`, and `grts_address` 
> (although the latter is non-mandatory/[[glossary/NULL|nullable]] in Observations).

The technical realization is explained below.

## View and Update Rules

Starting at the actual [[usage/qgis|QGIS]] **field forms**, we end up at a form which includes a separate tab for each major type of #Observations. 
For example, the form for `SURFLENTDATACOLL` has a **dedicated tab** for #PerturbationObservations where colleagues find a checklist with all the possible perturbations they should look out for (cow pats, roads, beavers, fences, ...).
That tab is not strictly mandatory: experienced researchers know the perturbation categories by heart and can skip that part of the form in case of all negative assessments.


The technical backend of the field form is a #view, in this case `"inbound"."FieldWork"` of #mnmsurfdb (found in `900_database_organization/views/surf_FieldWork.sql` or in the "Views" sheet of the [[database/generation|structure sheets]]).
Tracing back the information collected by that view, we can find a huge assembly of all the major REP-related tables mentioned above: #Visits, #FieldCalendars, and many metadata tables. 
Three major types of #Observations are also brought to the party: #SampleContextObservations, #PerturbationObservations and #MeteorolObservations.

> [!note] "Lazy Feature Creation"
> Whereas #Visits are predefined by the #REP and loaded to the database via a [[maintenance/REP update|REP update]],
> #Observations of specific types will only be created "at visit time", i.e. when a research colleague submits information via the field form.

The optional, *ad hoc* creation of Observations is handled by [[sql/update rules|update rules]].


## Update Rules: Example

To illustrate this, here are the update rules used to link novel or existing #SampleContextObservations to #Visits upon visit, on demand.
Just as in the figure above, the user toggles "omgevingsdata" for `plas` and thereby activates the tab, where Observation info is collected.
Depending on whether the specific observation exists (assessed by the `WHERE` condition in the rule below), an `INSERT` statement may be issued to create a new, linked Observation (see how `teammember_id`, the date from `datetime_visit`, and `grts_address` are provided as linking columns).

```sql
DROP RULE IF EXISTS fieldwork_ins_SCOBS ON "inbound"."FieldWork";
CREATE RULE fieldwork_ins_SCOBS AS
ON UPDATE TO "inbound"."FieldWork"
WHERE (NEW.samplecontextobservation_id IS NULL
  AND NEW.link_observation_samplecontext)
DO ALSO
 INSERT INTO "inbound"."SampleContextObservations" (
  teammember_id,
  date_visit,
  location,
  visit_id,
  is_linked_to_visit,
  grts_address,
  wkb_geometry
 ) VALUES (
  NEW.teammember_id,
  NEW.datetime_visit::date,
  CAST( NEW.grts_address AS varchar),
  NEW.visit_id,
  TRUE,
  NEW.grts_address,
  NEW.wkb_geometry
 )
;
```

This first rule ensures that an entry in the #Observations table exists when the user enters data, and it must be defined first after the View is created.
Then, a second `UPDATE` rule fills the other fields with the user input.

```sql
DROP RULE IF EXISTS fieldwork_upd_SCOBS ON "inbound"."FieldWork";
CREATE RULE fieldwork_upd_SCOBS AS
ON UPDATE TO "inbound"."FieldWork"
DO ALSO
 UPDATE "inbound"."SampleContextObservations"
 SET
  notes = NEW.samplecontext_notes,
  alert = NEW.samplecontext_alert,
  photo = NEW.samplecontext_photo,
  max_depth_cm = NEW.max_depth_cm,
  -- <...>,
  metaphyton = NEW.metaphyton
 WHERE
  samplecontextobservation_id = OLD.samplecontextobservation_id
  AND grts_address = OLD.grts_address
  AND visit_id = OLD.visit_id
;

```

Here, the `WHERE` condition makes sure that only the correct Observation is updated (`grts_address` alone should ensure that).