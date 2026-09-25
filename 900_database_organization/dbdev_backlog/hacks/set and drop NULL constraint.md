---
aliases:
tags:
  - constraints
  - NULL
---

```sql
ALTER TABLE "transfer"."ReplacementData" ALTER COLUMN sampleunit_id DROP NOT NULL;
ALTER TABLE "transfer"."ReplacementData" ALTER COLUMN sampleunit_id SET DEFAULT NULL;
```