---
aliases: replacement
tags: #loceval
---

procedure performed in case of a habitat type mismatch assessed in the field
in the hope of locally finding a replacement cell for the targeted habitat type


The data flow for a local replacement procedure, in a nutshell.

1. During #loceval, a sample unit is flagged as `SampleUnits.replacement_ongoing` ("lokale vervanging nodig"). ==🟣This simultaneously changes the field `TerrestrialTypesVisits.replacement_ongoing`.==
2. The #view #ReplacementOngoing picks up all sample units with that status, and displays **replacement candidate cells** from #Replacements. Those appear in a different map layer in #QGIS / #QField and must be subject to their own #loceval, in order of their `replacement_rank`. 
	- A replacement candidate can be `is_inappropriate`, which is `TRUE` for cells that do not possess the habitat type requirements.
	- In addition, we capture `type_suggested`, and `implications_habitatmap`.
	- Finally, `is_selected` flags *exactly one cell* which will be the actual replacement.
3. Upon update of the view, fields in #SampleUnits get updated as well via update rules.
	- `replacement_ongoing` to toggle off the replacement procedure
	- `replacement_reason` to note the reason for replacement (usually target habitat not present)
	- `replacement_permanence` to judge whether the original cell is gone for good
	- `type_is_absent` as the last flag to indicate that the whole replacement procedure was unsuccessful
	- `is_replaced` will turn off the replacement procedure for successful outcomes, and flag the units which have been replaced.
4. Link back to the #Visits, or actually only #TerrestrialTypesVisits, is convenient to complete filling the Visit-side forms even during a replacement procedure. ==🟣This initially happened via the sample unit, which led to ambiguous join and erroneous filling of `visit_done`. Therefore, the field `replacement_triggered` was added to only link to the latest visit which triggers a replacement.==
	- `Replacement_triggered` is filled with `replacement_ongoing`. It can be undone from the target unit, but not from the replacements, to ensure that there is always at least one visit joined to `ReplacementOngoing`.
5. Because replacement candidates can change with #REP revisions, we store #ReplacementArchives during `510_loceval_update_REP.qmd`. Those stay in the #Replacements table even in case of changes.
6. To sync with other databases, actual replacements are copied to #ReplacementData via #mnmsyncdb.


==🟣There also is a field `replacement_recovery_notes` which should be but is not yet stored on the replacement LocationInfos.==