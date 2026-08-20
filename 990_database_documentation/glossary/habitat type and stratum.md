---
aliases:
  - habitat type
  - type
  - stratum
tags:
  - type
  - stratum
  - habitat
---

The goal of the #MNE [[glossary/scheme|schemes]] is to infer status and trend on the level of major habitat type groups.
Our sample is stratified by habitat types (certain classes of ecological ensembles which are defined by the natura 2000 policy and which are under prioritized protection).
[*further information*](https://www.ecopedia.be/encyclopedie/habitattype)

## type

Technically, the `type` is a four digit code with occasional, defining suffix.
If the Flemish reality allowed for a non-arbitrary splitting of a type which was already at the finest classification level, then we add the suffix.
The first of the four digits defines the broad habitat class:

| **Nr** | **category** |
|------|-------------------------------------|
| `1*` | Kusthabitats of halofytenvegetaties |
| `2*` | Kust- en landduinen                 |
| `3*` | Zoetwaterhabitats                   |
| `4*` | Heidevegetaties                     |
| `6*` | Graslanden en ruigten               |
| `7*` | Venen                               |
| `9*` | Bossen                              |

(Note that there are exceptions, such as a couple of *heide*-types in other main numbers.)


## stratum

For aquatic types (`3*` and some out-groups), rough size categories of the lentic target units (water bodies) are distinct enough in their characteristic to expect different results (e.g. because of stratification = surface-to-bentos gradients or layers within water bodies of a certain size).
Therefore, we use `stratum` as a sub-field to `type` (mostly `stratum == type`, but for aquatic units there is an extra suffix).

+ In #locevaldb, `type` is sufficient; the assessment of `stratum` happens via auxiliary GIS analyses (e.g. surface area of the polygons).
+ In #mnmgwdb and #mnmsurfdb, we distinguish down to the level of `stratum`, and the stratum stands in as a [[glossary/characteristic columns|characteristic column]] for [[glossary/sample unit|sample units]].
+ The metadata table #N2kHabStrata allows conversion from one to the other.