---
aliases:
  - grts original
tags:
  - REP
  - GRTS
started:
finished:
execution:
status: false
---

Terminology in #REP:
- `grts_address` is the original sample
- `grts_address_final` is the adjusted location after potential local replacement in MHQ context

Terminology in the databases:
- `grts_address_final` renamed to `grts_address`
- original sample address *discarded*
- on top of that, [[procedures/local replacements|local replacement]] can further change the address (but the outcome is linked to and considered a replacement of the **original**)

For future reference, it makes sense to keep `grts_original` as an extra characteristic column in #SampleUnits 

Note: found a join issue for `Replacements` [[timeline/2026-06-16|2026-06-16]]