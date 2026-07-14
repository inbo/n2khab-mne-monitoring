---
aliases:
  - union of #CellMaps for random placement points if colocated types can be combined
tags:
  - RandomPoints
  - CellMaps
started:
finished:
execution:
status: false
---

see mail #KW [[timeline/2026-07-14|2026-07-14]]

Random dots should be generated in the union of the cell mapping polygons of the types attached to the grid cell (i.e. when at least one cell-center linked type combines with one or more cell-linked types).


| **type** | **type_shortname**                 | **GW_03.3** | **GW_05.1_terr** | **SOIL_03.2** |
|:---------|:-----------------------------------|:-----------:|:----------------:|:-------------:|
| 1320     | schorren met slijkgras             |             |      X           |               |
| 2150     | vastgelegde ontkalkte duinen       |             |                  |     X         |
| rbbsg    | brem- en gaspeldoornstruweel       |             |                  |     X         |
| 6210_sk  | kalkrijke zomen en struwelen       |             |                  |     X         |
| 6430_bz  | nitrofiele boszoom                 |             |      X           |     X         |
| 7150     | pioniervegetaties met snavelbiezen |    X        |      X           |     X         |
| rbbsp    | doornstruweel                      |    X        |                  |     X         |
