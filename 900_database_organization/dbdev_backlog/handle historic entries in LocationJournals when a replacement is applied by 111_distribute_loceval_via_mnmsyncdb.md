---
aliases:
tags:
  - LocationJournals
  - localreplacement
started:
finished:
execution:
status: false
---

It makes sense to keep all past LoJo activities on the original `grts_address`.
Currently, the script `111_distribute_loceval_via_mnmsyncdb.R` filters for "visit not done" and will only move activities to a new sample unit which have not been finished by the time of script execution.
This should prevent `112_fill_location_journals.R` from re-uploading / duplicating previous activities.
Which is good.

Or not? 
Is continuity of activities to be guaranteed?