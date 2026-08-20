---
aliases:
tags:
started:
finished:
execution:
status: false
---

i noticed

`# \d+ "transfer"."ReplacementData"`

|   Column        |    Type           | Storage      |
|-----------------|-------------------|--------------|
| `<all other>`   | integer           | plain        |
|  type           | character varying | **extended** |

given that this is a major join column, consequently fixing data type length should give a considerable performance increase