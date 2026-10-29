---
aliases:
  - photos
  - photo organization
tags:
  - photos
---

## Taking Photos

Photos taken in the field are stored on mobile devices and attached to the #QField projects.
The attachment is dual: 
+ photos are copied to or stored directly in the `DCIM` subfolder of the project.
+ File names and paths (usually relative) to these photos are stored in the database as a text string.

This is realized by assigning the "attachment" data type to the photo field in #QGIS. 
The application thereby knows that the string is a photo path, and displays the image if it is present on the device.

Initially, a photo taken by a colleague in the field will only be visible on the device on which it was taken.
To distribute it to others, it must be exported and uploaded, then processed and distributed.

## Exporting and Uploading Photos

![[usage/qfield#Photo Export]]

Another option is do grap all photos via the "Android Debug Bridge", using `adb pull "/storage/emulated/0/Android/data/ch.opengis.qfield/"`.

> [!warning] QField Android Photo Management
> Managing photos on Android is tricky.
> 
> - Existing photos are shared with the `.zip` project file, which makes them heavy to share.
> - Prior photos are also exported, and "the new" must be sorted from "the previous" later on.
> - Every new version of a QField project gets its own copy of the `DCIM` folder. This costs phone space.
> - Because of that, an export only picks the latest iteration of the project, and we might miss novel photos on previous subfolders.
> 
> To overcome these issues, we plan to investigate options for web storage in the future.
> For now, "it is what it is".



## Processing
Usually, photos are shared in `.zip` batches.
For further processing, these must be unpacked into a subfolder adjacent to the collection script.

[A Python collection script is available](https://github.com/inbo/n2khab-mne-monitoring/blob/db_tooldev/900_database_organization/941_consolidate_incoming_photos.org) to iteratively find all photo files of certain formats and move only the novel ones to a destination folder.
This script takes file size and creation date into account to distinguish the original file from redistributed files of reduced quality.
The script also uses [`imagemagick`](https://imagemagick.org) (an alternative would be [`ffmpeg`](https://ffmpeg.org)) to convert the high res photos to a version in lower resolution (sufficient to view, but less heavy to share).

In essence, the novel photos are thus (i) stored in the `photos_highres` archive, and (ii) added to the `DCIM` folder for use in QGIS and distribution for QField.


## Sharing

Photos are stored as a location reference and for other INBO teams to browse, providing a location overview prior to fieldwork by others, and a snapshot of the situation and circumstances at the moment of a given activity.
These are stored in a specific folder structure, and the script `900_database_organization/940_sort_photos_for_sharing.py` is a quick tool for copying all available photos into that structure, based on information from our database.


> [!note] Note to Self
> occasionally helpful:
> - zip only image files with `find . -iname \*.jpg -o -iname \*.png | zip -9 -@ photos.zip`

A low-res version of each photo is [[procedures/packaging a QGIS project for QField|distributed with the QField projects]].