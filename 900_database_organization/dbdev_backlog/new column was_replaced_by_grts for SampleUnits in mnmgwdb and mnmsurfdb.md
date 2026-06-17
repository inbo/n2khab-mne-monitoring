---
aliases:
  - store replacement cell in the original sampleunits
tags:
  - SampleUnits
  - localreplacement
started: 2026-06-08
finished: 2026-06-08
execution:
  - FM
status: true
---

During [[structure/distribute loceval information via mnmsyncdb]] I noticed the `is_replacement` field which seemingly correctly flags the units which are the replacement of another cell.
However, I saw no way of linking to the replacement from the original unit.

Instead of boolean flag, the GRTS reference might be useful (`WHERE was_replaced_by_grts IS NULL` for the unreplaced ones).

```sql
COMMENT ON COLUMN "outbound"."SampleUnits".is_replacement IS E'whether or not this is a replacement cell';
ALTER TABLE "outbound"."SampleUnits" ADD COLUMN was_replaced_by_grts int; 
COMMENT ON COLUMN "outbound"."SampleUnits".was_replaced_by_grts IS E'GRTS address of the replacement of this unit';

```

update using #ReplacementData:
```sql
UPDATE "outbound"."SampleUnits" AS SUNITS
SET was_replaced_by_grts = REP.grts_address_replacement
FROM "transfer"."ReplacementData" AS REP
WHERE REP.grts_address_original = SUNITS.grts_address
;
```

*(53 units received a link, which is only half of the actual number of replacements.)*