---
aliases:
  - FreeFieldNotes symbols
tags:
  - FreeFieldNodes
  - symbols
  - layout
started: 2026-07-15
finished: 2026-07-16
execution:
  - FM
status: true
---


```sql
ALTER TABLE "inbound"."FreeFieldNotes" ADD COLUMN special_symbol varchar; 
COMMENT ON COLUMN "inbound"."FreeFieldNotes".special_symbol IS E'this field categorizes fieldnotes with the purpose of attaching a visual emphasis via map layer symbology';
```

# auto updates
## parking
```sql
-- SELECT * FROM
UPDATE
"inbound"."FreeFieldNotes"
SET special_symbol = 'parking'
WHERE special_symbol IS NULL
  AND (LOWER(field_note) LIKE 'park%'
   OR  LOWER(field_note) LIKE '%park%')
;
```

## ingang (includes bridges)
```sql
-- SELECT * FROM
UPDATE
"inbound"."FreeFieldNotes"
SET special_symbol = 'ingang'
WHERE special_symbol IS NULL
  AND (LOWER(field_note) LIKE 'ingang%'
   OR  LOWER(field_note) LIKE '%ingang%'
   OR  LOWER(field_note) LIKE '%bereiken%'
   OR  LOWER(field_note) LIKE '%toegang%'
   ) AND NOT LOWER(field_note) LIKE '%klautertoegang%'
;

```

## brug
```sql
-- SELECT * FROM
UPDATE
"inbound"."FreeFieldNotes"
SET special_symbol = 'brug'
WHERE special_symbol IS NULL
  AND (LOWER(field_note) LIKE 'brug%'
   OR  LOWER(field_note) LIKE '%brug%')
;
```

## poort
```sql
-- SELECT * FROM
UPDATE
"inbound"."FreeFieldNotes"
SET special_symbol = 'poort'
WHERE special_symbol IS NULL
  AND (LOWER(field_note) LIKE 'poort%'
   OR  LOWER(field_note) LIKE '%poort%')
;
```

## waadpak
```sql
-- SELECT * FROM
UPDATE
"inbound"."FreeFieldNotes"
SET special_symbol = 'waadpak'
WHERE special_symbol IS NULL
  AND (LOWER(field_note) LIKE 'waadpak%'
   OR  LOWER(field_note) LIKE '%waadpak%')
;
```

## others
```sql
SELECT * FROM
"inbound"."FreeFieldNotes"
WHERE special_symbol IS NULL
;
```

```sql
-- SELECT * FROM
UPDATE
"inbound"."FreeFieldNotes"
SET special_symbol = 'nest'
WHERE special_symbol IS NULL
  AND LOWER(field_note) LIKE '%ooievaar%'
;
```

```sql
-- SELECT * FROM
UPDATE
"inbound"."FreeFieldNotes"
SET special_symbol = 'beasts'
WHERE special_symbol IS NULL
  AND LOWER(field_note) LIKE '%verzwijn%'
   OR LOWER(field_note) LIKE 'stier%'
   OR LOWER(field_note) LIKE 'bever%'
   OR LOWER(field_note) LIKE '%bever%'
;
```

```sql
-- SELECT * FROM
UPDATE
"inbound"."FreeFieldNotes"
SET special_symbol = 'monument'
WHERE special_symbol IS NULL
  AND LOWER(field_note) LIKE 'p-plaats%'
;
```

```sql
-- SELECT * FROM
UPDATE
"inbound"."FreeFieldNotes"
SET special_symbol = 'klautertoegang'
WHERE (special_symbol IS NULL OR TRUE)
  AND LOWER(field_note) LIKE '%klautertoegang%' 
;

```

# image references
+ `parking`: used QGIS svg symbol layer
+ `nest` <https://www.svgrepo.com/svg/74383/birds-eggs-on-a-nest>
+ `brug` <https://thenounproject.com/icon/bridge-8321247/>
+ `poort` <https://thenounproject.com/icon/entrance-5746367/>
+ `geen doorgang` <https://thenounproject.com/icon/stop-3152858/>
+ `ingang` <https://thenounproject.com/icon/login-3036818/>
+ `sonnebril` <https://thenounproject.com/icon/sunglasses-7528457/>
+ `waadpak` <https://thenounproject.com/icon/wading-overall-8107034/>
+ `beasts` -> everzwijn stier <https://thenounproject.com/icon/crocodile-7996742/>
+ `climbing` -> klautertoegang <https://thenounproject.com/icon/climbing-8423343/>
+ `monument` -> P-plaats <https://commons.wikimedia.org/wiki/File:Manneken_Pis.svg>