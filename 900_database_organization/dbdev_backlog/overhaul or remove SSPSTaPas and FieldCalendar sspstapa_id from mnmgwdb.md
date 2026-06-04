---
aliases:
  - overhaul or remove SSPSTaPas
tags:
  - mnmgwdb
  - SSPSTaPas
started:
finished:
execution:
status: false
---

> [!note] SSPSTaPas
> stands for "stratum + scheme + panelset + targetpanels"

> [!warning] The #SSPSTaPas table is dysfunctional.
> `sspstapa_id` is empty in the #FieldCalendar of #mnmgwdb.

Back in the days, it seemed like a good idea to create a #metadata table which replaces all these concatenated strings with a lookup index.
This worked fine; however, there was extra overhead and little perceived use of that field.
At some point, I simply replaced the content by `NA` values.