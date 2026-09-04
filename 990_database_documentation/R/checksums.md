---
aliases:
  - checksums
tags:
  - R
  - REP
---
Data objects from the [[R/Code Snippets|snippets]] may not differ across users and machines.
For that purpose, checksums are generated upstream during [[glossary/revisit plan|revisit plan]].

Those checksums are stored in the following file, on the repo base path:
```
fieldworg_checksums.csv
```

Those are a [`digest`](https://cran.r-project.org/web/packages/digest/index.html) with the `xxhash64` algorithm.