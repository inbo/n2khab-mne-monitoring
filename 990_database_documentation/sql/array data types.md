---
tags:
  - arrays
  - array
  - datatypes
---
Array data types are chosen for SQL fields which may contain more than one value.
They can be defined for most of the base data types in [[sql/sql|sql]] by either using the `ARRAY` declaration or adding square bracket to a data type, e.g. `int[]` or `character varying[]`.
Arrays have specific advantages and disadvantages, and require some considerations ([[database/design guidelines|design guidelines]]).

The first occurrence of array types in our databases were modified connections between #FieldCalendars and #Visits in #mnmsurfdb:
due to [[glossary/matching occasions|matching occasions]], a single "visit" can serve multiple planned "field activities" in the calendar, justifying a `1:n` relation between the tables.


Some references:
- <https://www.postgresql.org/docs/current/arrays.html>
- <https://www.geeksforgeeks.org/postgresql/postgresql-array-data-type/>
- <https://www.pgtutorial.com/postgresql-tutorial/postgresql-array/>
 