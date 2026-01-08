---
aliases:
  - qgis
tags:
  - gis
---

- <https://qgis.org>
- GDAL dependency:
> Zonet had ik een probleem met GDAL versieconflicten: er is een nieuwere versie, en mijn R vraagt die, maar mijn systeem is nog niet op de laatste stand.
> Dus, gdal van github lokaal compilen, een softlink kopieren via `sudo cp libgdal.so.38 /usr/lib/` et voila, ik heb weer de laatste sf en terra

- Or, the other way round. If a program requires an oder gdal version, softlinking the newer one might fake it: `sudo ln -s /path/to/libgdal.so /usr/bin/libgdal.so.36`


## Plugins

- `QField Sync`
- `changeDataSource`
