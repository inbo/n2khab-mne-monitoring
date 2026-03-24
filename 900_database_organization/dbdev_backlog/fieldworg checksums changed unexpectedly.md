---
aliases:
tags:
  - checksums
  - snippets
started: 2026-03-20
finished: 2026-03-24
execution:
  - FM
  - FV
status: true
---

[[tags/checksums]] suddenly changed
reason turned out to be an R package update

Solved by #FV after some research:
- previous version of #snippets restored
- downgraded R, then downgraded R package versions (`renv`!)
- then compared old and new data via loading in different env's

Adjusted checksum file PR'd to `main` for easy merge.


---
*initial observation #FM:*
I do not remember what exactly started it

was in the process of fixing an issue with  `reload_rep_code_snippets` in `MNMLibraryCollection.R`
realizing that a change in `rename_grts_address_final_to_grts_address` of `grts.R` had not changed
added the `source_snippet_supplements` trick with `snippet_base_path <<-` trick
recalculating `403_precalculate_fresh_snippets.R` then suddenly gave checksum errors (after auto-downloading the #RData file):

```
|name                                                        |xxh64sum_ref     |xxh64sum_current |
|:-----------------------------------------------------------|:----------------|:----------------|
|actseqs_actgroups_acts                                      |1b972aa7e9620891 |615e5e3bf8586fa6 |
|fag_fa                                                      |c130524775f5c328 |a94bc71f5d70431e |
|fag_grts_calendar_shortterm_attribs                         |9d96d5e33c7ea2d2 |315c74ba33f5bc5f |
|fag_grts_calendar_shortterm_attribs_sf                      |46438fc3b3d5e349 |0645b64ffb3ae639 |
|fag_stratum_grts_calendar_shortterm_attribs                 |5b7f4006fbd54683 |3cbc26fdcf69bbec |
|faseqs                                                      |5dc3f66af8bcf6cf |b43fd9370e6d306d |
|faseqs_fag_fa                                               |1ee4431596a602c9 |f084f35b8cb8215a |
|fieldwork_shortterm_dates_prioritization_count              |326a4ec94b4b6765 |2b4f97e84fa7f3b5 |
|fieldwork_shortterm_prioritization_by_stratum               |acc2c135400db469 |6c712db971492de6 |
|fieldwork_shortterm_targetpanels_prioritization_count       |180eb5e30a635172 |f0e667c94e6dd2af |
|grts_mh_brick_lev3_index                                    |9efacd826e1122bd |3af15ea087d3f402 |
|grts_mh_index                                               |cc0093c9b3cdda04 |29b5da5e3db0f75d |
|orthophoto_shortterm_cell_centers                           |d7b11560d36ff7bf |6bfbc583ae00c470 |
|orthophoto_shortterm_cells                                  |f59cb449d03055b5 |65ac53f176e93c23 |
|orthophoto_shortterm_type_grts                              |0620bf7a7b01795a |392e37646ccae1ad |
|scheme_moco_fa_fieldvar                                     |f9a48c975615e676 |07be3a69a8cf78d9 |
|scheme_moco_ps_stratum_targetpanel_spsamples                |632ca8e3fe48ad12 |3b93349c43d5183c |
|schemepstargetpanel_spsamples_terr                          |4fa70b5709aa47a1 |a732571d8edda038 |
|stratum_schemepstargetpanel_spsamples                       |2885d7392ce41334 |d15c2d122f09a0cb |
|stratum_schemepstargetpanel_spsamples_terr_replacementcells |688a7542e7e432d3 |4d20f9d351313f63 |
|units_7220                                                  |c74c1989dd192fbd |1f6b0b5bad0ab505 |
|units_cell_polygon                                          |423223bc330499d9 |7dbb9989ad8b5a10 |
|units_cell_polygon_attrib                                   |a3843bf793d028e1 |d0006d102c8c6c59 |
|units_cell_polygon_stratum_attribs                          |76599ccf2f1fbfaa |1772fbe6346c9d9a |
```

Further notes:
- There was an R update in the morning
- remarkably, all checksums changed at once
- Should I store previous versions of `fresh_snippet_workspace.RData` for safety?