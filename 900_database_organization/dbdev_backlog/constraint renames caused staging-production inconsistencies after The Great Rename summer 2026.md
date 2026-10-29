---
aliases:
tags:
started: 2026-09-10
finished:
execution:
  - FM
status: false
priority: 1
---

During the first `dump-restore` of #mnmgwdb production to #staging, some errors popped up.
They disappeared on the second dump-restore, which indicates that the status quo of the #production database is inconsistent with the [[locations/structure sheets|structure sheets]].

-> find the primary cause and gently adjust production.

```
ERROR:  constraint "fk_versions_samplelocations" of relation "SampleUnits" does not exist
ERROR:  constraint "fk_versions_fieldworkcalendar" of relation "FieldCalendars" does not exist
ERROR:  constraint "fk_teammembers_fieldworkcalendar" of relation "FieldCalendars" does not exist
ERROR:  constraint "fk_sspstapas_fieldworkcalendar" of relation "FieldCalendars" does not exist

ERROR:  index "randompoints_wkb_geometry_geom_idx" does not exist

ERROR:  constraint "pk_randompoints_fid" of relation "InstallationPoints" does not exist

ERROR:  constraint "SampleLocations_pkey" of relation "SampleUnits" does not exist
ERROR:  constraint "RandomPoints_randompoint_id_key" of relation "InstallationPoints" does not exist

ERROR:  constraint "FieldworkCalendar_pkey" of relation "FieldCalendars" does not exist

ERROR:  cannot drop constraint Versions_pkey on table metadata."Versions" because other objects depend on it
DETAIL:  constraint fk_versions_sampleunits on table outbound."SampleUnits" depends on index metadata."Versions_pkey"
constraint fk_versions_fieldcalendars on table outbound."FieldCalendars" depends on index metadata."Versions_pkey"
HINT:  Use DROP ... CASCADE to drop the dependent objects too.

ERROR:  cannot drop constraint TeamMembers_pkey on table metadata."TeamMembers" because other objects depend on it
DETAIL:  constraint fk_teammembers_fieldcalendars on table outbound."FieldCalendars" depends on index metadata."TeamMembers_pkey"
HINT:  Use DROP ... CASCADE to drop the dependent objects too.

ERROR:  cannot drop constraint SSPSTaPas_pkey on table metadata."SSPSTaPas" because other objects depend on it
DETAIL:  constraint fk_sspstapas_fieldcalendars on table outbound."FieldCalendars" depends on index metadata."SSPSTaPas_pkey"
HINT:  Use DROP ... CASCADE to drop the dependent objects too.

ERROR:  sequence "seq_randompoint_id" does not exist

ERROR:  sequence "seq_fieldworkcalendar_id" does not exist

ERROR:  view "SampleLocations" does not exist

ERROR:  sequence "RandomPoints_ogc_fid_seq" does not exist
ERROR:  view "RandomPoints" does not exist

ERROR:  view "RandomCellPoints" does not exist

ERROR:  view "LocationEvaluations" does not exist

ERROR:  view "FieldworkCalendar" does not exist

ERROR:  view "CellMaps" does not exist

ERROR:  cannot drop table metadata."Versions" because other objects depend on it
DETAIL:  constraint fk_versions_sampleunits on table outbound."SampleUnits" depends on table metadata."Versions"
constraint fk_versions_fieldcalendars on table outbound."FieldCalendars" depends on table metadata."Versions"
HINT:  Use DROP ... CASCADE to drop the dependent objects too.
ERROR:  cannot drop table metadata."SSPSTaPas" because other objects depend on it
DETAIL:  constraint fk_sspstapas_fieldcalendars on table outbound."FieldCalendars" depends on table metadata."SSPSTaPas"
HINT:  Use DROP ... CASCADE to drop the dependent objects too.

ERROR:  sequence "seq_fieldwork_id" does not exist

ERROR:  cannot drop table metadata."TeamMembers" because other objects depend on it
DETAIL:  constraint fk_teammembers_fieldcalendars on table outbound."FieldCalendars" depends on table metadata."TeamMembers"
HINT:  Use DROP ... CASCADE to drop the dependent objects too.

ERROR:  cannot drop schema metadata because other objects depend on it
DETAIL:  table metadata."Versions" depends on schema metadata
table metadata."TeamMembers" depends on schema metadata
table metadata."SSPSTaPas" depends on schema metadata
HINT:  Use DROP ... CASCADE to drop the dependent objects too.

ERROR:  schema "metadata" already exists

ERROR:  relation "TeamMembers" already exists

ERROR:  relation "SSPSTaPas" already exists

ERROR:  relation "Versions" already exists

ERROR:  multiple primary keys for table "SSPSTaPas" are not allowed

ERROR:  multiple primary keys for table "TeamMembers" are not allowed

ERROR:  multiple primary keys for table "Versions" are not allowed

```