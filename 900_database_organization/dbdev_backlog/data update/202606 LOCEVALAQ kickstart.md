---
aliases:
  - kick-off loceval of aquatic habitat types
tags:
  - locevaldb
  - aquatictypes
  - TargetPoints
  - SamplingPoints
  - YOLO
started: 2026-06-26
finished:
execution:
  - FM
status: false
---

goals:
- recent (intermediate) #REP data deployed on #locevaldb
- LOCEVALAQ in database and in #QGIS project -> #AquaticTypesVisits 
	+ `crassula_was_here`
- SAMPLPOINT activity / #TargetPoints implemented
- extracurricular locevals - location-independent but structurally identical to real terrestrial/aquatic #loceval

# prep
+ merge latest [`snippets_activate_surf`](https://github.com/inbo/n2khab-mne-monitoring/tree/snippets_activate_surf)
+ load latest RData

# LOCEVALAQ database layout
much was prepared [[timeline/2026-06-18#Major Structural Adjustments on locevaldb|2026-06-18]]

+ move `replacement_recovery_notes` to #TerrestrialTypesVisits
```sql

```

+ new table #TargetPoints
```sql
```


