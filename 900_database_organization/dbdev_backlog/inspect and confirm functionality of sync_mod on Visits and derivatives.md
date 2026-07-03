---
aliases:
  - trigger the children
tags:
  - trigger
  - Visits
  - sync_mod
started:
finished:
execution:
status: false
---

there seems to have been an issue with #sync_mod on #locevaldb #Visits 
```sql
DROP TRIGGER IF EXISTS log_extravisits ON "inbound"."Visits";
DROP TRIGGER IF EXISTS log_visits ON "inbound"."Visits";
CREATE TRIGGER log_visits
BEFORE UPDATE ON "inbound"."Visits"
FOR EACH ROW EXECUTE PROCEDURE "metadata".sync_mod();
```

Issue: Visits is a parent interface; trigger might not trigger on derived tables
-> try adding a trigger for all the children
