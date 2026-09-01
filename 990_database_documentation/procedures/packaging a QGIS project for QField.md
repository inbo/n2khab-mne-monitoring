---
tags:
  - QGIS
  - QField
  - mobile
---

## QField Sync
Projects for fieldwork are prepared in #QGIS, but exported to #QField via the **QField Sync Plugin**.
To install it, find it in the `plugin manager` in QGSI (menu `Plugins` --> `manage and install plugins').

![[attachments/qgis_qfield_sync_plugin.webp]]

Note that there is a new tab with QField settings in the layer properties of each map layer.
- Database layers should be set to "`directly access data source`", with editing permissions as restrictive as possible.
- Geopackage layers should be set to "offline editing" (although they are usually not edited).

## Paths
To ensure that all content of the project is correctly (and not doubly) distributed, the following settings are recommended.

1) Set the project "save paths" setting to "Relative".
    ![[attachments/qfield_relativepaths_1.webp]]
2) Set the path of auxiliary datasets to a relative path. ==Note that this will only work relative to the QGIS execution path.==
    ![[attachments/qfield_relativepaths_2.webp]]
3) Make sure the QField Sync export will store to a full path (no symlinks, no relative path).
    ![[attachments/qfield_relativepaths_3.webp]]


## Distribution Helper Script

A shell script for the fish shell which will bring in photos, zip project folder content and distribute the `.zip` file.
```sh
#!/usr/bin/env sh

declare -a projects=(
  "loceval_fieldwork"
  "mnmgwdb_fieldwork"
  "mnmsurfdb_fieldwork"
)

for prj in "${projects[@]}"
do
  echo "### $prj" 

  echo "  - retrieving photos" 
  rm -rf "$prj/DCIM"
  cp -R -p "./DCIM" "$prj/"

  echo "  - zipping project" 
  cd $prj
  rm -f "*.qgs~"
  rm -f "../$prj.zip"
  zip -ruq "../$prj.zip" . -i '*'
  cd ..

  echo "  - distributing" 
  cp "$prj.zip" "./distribute/"
done


```

## Photos
As you see in the script above, we grab the latest DCIM folder with recent fieldwork photos for every project. 
For more details on how to get them back, see [[procedures/photo sharing and distribution|photos]].