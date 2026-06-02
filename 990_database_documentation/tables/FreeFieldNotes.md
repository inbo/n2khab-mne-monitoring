---
aliases:
  - FiNos
  - "inbound"."FreeFieldNotes"
tags:
  - FreeFieldNotes
  - inbound
---
*Free notes to be placed on a point on the map, usually related to field visits.*

## Structure

| column           | comment                                                                   |
|------------------|---------------------------------------------------------------------------|
| fieldnote_id     | note index                                                                |
| **log_creator**  | *(technical)* user who created the entry                                  |
| **log_creation** | *(technical)* timestamp of creation                                       |
| log_user         | *(technical)* user who modified the entry                                 |
| log_update       | *(technical)* timestamp of last modification                              |
| log_origindb #mnmsyncdb  | *(technical)* database which submitted the entry (loceval/mnmgwdb/...)    |
| archive_date #mnmsyncdb  | the day (YYYYMMDD) when this note was removed                     |
| hide             | used to hide completed notes                                              |
| teammember_id    | link to the user who performed the visit                                  |
| field_note       | description of the issue                                                  |
| note_date        | date of the field activity                                                |
| location         | free reference to the location (e.g. database id or grts address)         |
| activity         | what activity was performed (reference to GroupedActivities)              |
| photo            | an optional photo of the site or noteworthy thing                         |
| audio            | audio message to brighten up your rainy days                              |
| wkb_geometry     | Point geometry (31370 / Lambert 72): target location as well-known binary |



One way to interpret the *free* nature of these notes is that they are not coupled to a `grts_address`, as most of our spatial geometries.
Notes can be set at any point on the map.
This also means that the table **does not contain [[glossary/characteristic columns|characteristic columns]] *sensu stricto***. 
We use `characteristic_columns <- c("log_creator", "log_creation")` to work around this[^1]. 
These are tied to the SQL [[server/users|user]] who created it, and the creation timestamp (in milliseconds) is what uniquely defines a note.

[^1]: Although the place of a note might qualify as an identifier, our data model allows for moving of notes, and thus `wkb_geometry` is not considered characteristic of `FreeFieldNotes`.

The user can enter and edit most of the fields; photo and audio media entry is encouraged (as in: "free to store what you want") to simplify information capture.

## Synchronization

This table is shared across databases, but has to be synchronized to make sure notes spread to all colleagues.
The script in charge is `119_sync_FreeFieldNotes.R` (historically, there was a Python script with the same name, with much less thorough comparisons).

All input databases sync against #mnmsyncdb, and changes are distributed.
Handling the `fieldnote_id` is particularly tricky, and care must be taken that all indices/sequences are adjusted upon sync.
The `log_update` field is crucial to determine which database carries the most recent changes.
Field notes can be deleted, but only if the deletion happens on their original database (stored as `log_origindb` on #mnmsyncdb).
Those notes will remain in the synchronization database, but with an `archive_date` flag.

Sharing of photos happens like with regular [[procedures/photo sharing and distribution|photos]]; sharing of audio recordings will work analogously but has not occurred yet.