---
aliases:
  - double-check LoJo output
tags:
  - LocationJournals
  - check
started:
finished:
execution: 
status: false
---
When adding #mnmsyncdb to the script `111b_fill_location_journals.R`, I noticed that fewer rows remain in that database than in the others.

This is to be investigated.
```
<Id> "inbound"."InstallationRemovals": 0 rows uploaded, 2/0 existing judging by 'grts_address, date'.
ERROR: date missing on loceval for 22726,29073,5848641,7733982,48963798,55049430
ERROR: date missing on gw activity for 183033,7151026,31496054,51431410,53288370
<Id> "outbound"."LocationJournals": 0 rows uploaded, 871/0 existing judging by 'grts_address, date, source, activity_group_id'.
<Id> "outbound"."LocationJournals": 6 rows uploaded, 943/6 existing judging by 'grts_address, date, source, activity_group_id'.
Registered 6 new journal entries for loceval_staging.
<Id> "outbound"."LocationJournals": 5 rows uploaded, 875/5 existing judging by 'grts_address, date, source, activity_group_id'.
Registered 5 new journal entries for mnmgwdb_staging.
```