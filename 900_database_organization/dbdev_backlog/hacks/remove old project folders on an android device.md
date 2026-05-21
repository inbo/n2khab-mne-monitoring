---
aliases:
tags:
---

First: copy photos!
```sh
adb pull "/storage/emulated/0/Android/data/ch.opengis.qfield/"
```

ONLY  THEN remove old projects

```sh
adb shell "rm -rf /storage/emulated/0/Android/data/ch.opengis.qfield/files/Imported\ Projects/loceval_fieldwork_1"
```
