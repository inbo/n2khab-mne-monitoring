---
aliases:
  - unnecessary replacement fields in SampleUnits of mnmsurfdb
tags:
  - SampleUnits
  - mnmsurfdb
  - Replacements
started:
finished:
execution: DDG
status: false
---

In the heat of battle, #SampleUnits on the #mnmsurfdb database were copied from #locevaldb.
Copying included excess fields which are used for handling #localreplacements in the origin database.

- Make sure these fields are not used in the QGIS field forms.
- Make sure that there is no data in these fields for SampleUnits which are part of the current sample.
- Remove these columns (on staging) to double check and confirm that QGIS project and maintenance scripts stay functional.

