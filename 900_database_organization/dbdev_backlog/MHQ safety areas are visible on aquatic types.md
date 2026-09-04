---
aliases:
tags:
  - mnmsurfdb
  - MHQ
started:
finished:
execution:
status: false
---

those "red zones" make no sense on aquatic sample units; they appear as an artifact because I am not filtering out aquatic types during mhq upload.
Still, I dare not to entirely leave them out of `mnmsurfdb`.
Filtering should be simple; however, I would prefer an `is_aquatic` flag just as we have `is_forest` for a more robust and general implementation (who knows what future types colleagues come up with).