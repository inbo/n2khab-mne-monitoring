---
aliases:
tags:
  - userroles
  - permissions
  - FreeFieldNotes
started: 2026-06-02
finished: 2026-06-02
execution:
  - FM
status: true
---

Historically, users did have direct permissions to access database tables.
Then, we [[users/introduce roles|introduced roles]].

Now early users have double access to tables, for example:

```sql
-- \dp "inbound"."FreeFieldNotes"

| Schema  | Name           | Type  | Access privileges          | Column privileges | Policies |
|---------|----------------|-------|----------------------------|-------------------|----------|
| inbound | FreeFieldNotes | table | <admin>=arwdDxtm/<admin> + |                   |          |
|         |                |       | <user>=arwd/<admin>      + |                   |          |
|         |                |       | user_loceval=awd/<admin>   |                   |          |
```

*Note: `<user>` gets permission twice: via role `user_loceval` and directly from historical settings.*

(1) revoke:
`REVOKE ALL PRIVILEGES ON "inbound"."FreeFieldNotes" FROM <user>;`

(2) restore:
```sql
GRANT INSERT ON "inbound"."FreeFieldNotes" TO user_loceval;
GRANT UPDATE ON "inbound"."FreeFieldNotes" TO user_loceval;
GRANT REVOKE ON "inbound"."FreeFieldNotes" TO user_loceval;
```
(This was necessary because after revoking for all users, the groups were also missing.)

## batch permission modification
... is available in `900_database_organization/119_sync_FreeFieldNotes.R`.
Includes a `reg.finalizer` to restore permissions at any weird end of a ride.