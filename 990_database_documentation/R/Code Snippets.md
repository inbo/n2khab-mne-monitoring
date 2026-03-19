---
aliases:
  - snippets
tags:
  - snippets
  - codesnippets
  - R
  - REP
---
The "code snippets" are a set of R scripts which are used to transform the #REP output into objects ready for database import.
They are the coupling of the #R -generated revisit plans to the #database .


#### updating snippets
Currently, code can be found in `020_fieldwork_organization`, with the go-to script `020_fieldwork_organization/code_snippets.R`.
However, because things tend to break on both sides (updates of the REP bringing major changes *versus* updates of the snippets not merged to `main`), we maintain an extra safety layer.
Working components of the #snippets are synced manually with `900_database_organization/401_snippet_selection.R`. 

The process of syncing is fulfilled by [meld](https://meldmerge.org) or similar diff tools:
```sh
meld 020_fieldwork_organization/code_snippets.R 900_database_organization/401_snippet_selection.R
```
And that occasion is combined with exercising due diligence on the snippet code, and port novel concepts and connections to the rest of the codebase.