---
aliases:
  - mirrors
---
- ∀ <db> ⊆ `{loceval, mnmgwdb}`:
    - `<db>_dev` -> structural development
	- `<db>_testing` -> front-end testing (different roles)
	- `<db>_staging` -> equivalent copy of production
	- `<db>` -> **production**
- clone one to the other:

![[copy database]]