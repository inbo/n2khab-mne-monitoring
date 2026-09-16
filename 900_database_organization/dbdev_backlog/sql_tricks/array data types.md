---
aliases:
tags:
started:
finished:
execution:
status: false
priority:
---

https://www.postgresql.org/docs/current/arrays.html
https://www.geeksforgeeks.org/postgresql/postgresql-array-data-type/
https://www.pgtutorial.com/postgresql-tutorial/postgresql-array/
https://vrcacademy.com/tutorials/postgresql-arrays/


- declaration: `array_field integer[]` OR `array_field integer ARRAY`
- for SELECT: slicing and indexing possible (just as in Python, but starting at 1)
- for INSERT/UPDATE: `'{"string2", "string2"}'`, `'{{1,2,3},{4,5,6},{7,8,9}}'`, `ARRAY[25000,25000,27000,27000]`
- length can be given, e.g. `xy integer[2]`
- `search_value = ANY(array_field)` (`ANY`, `ALL`)
- `ARRAY_APPEND(array_field, 'new_element')`, `ARRAY_PREPEND`
- `ARRAY_REMOVE(array_field, 'existing_element')`
- `ARRAY_AGG` <> `UNNEST` / `UNNEST(array_field) WITH ORDINALITY AS`
- nesting is possible, e.g. `array_field integer[][]`
- `ARRAY_LENGTH`, `CARDINALITY`
- concatenation with `||`
- `STRUNG_TO_ARRAY`

Array containment:
- `<@` checks if array is contained in another
- `@>` checks if array contains another (i.e. multiple / AND)
- `&&` overlaps (i.e. multiple / OR)

Array indexing:
```sql
CREATE INDEX idx_skills_gin ON employee_skills USING GIN(skills);
```