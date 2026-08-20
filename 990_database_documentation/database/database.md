---
aliases:
  - db
  - databases
---

currently, we use multiple databases to co-ordinate our branches of fieldwork:
- #loceval for location evaluation tasks
- #mnmgwdb for organizing actions with regard to groundwater related installations
- #mnmsurfdb is implemented to co-ordinate monitoring related to the surface water compartment

Additionally, there is #mnmsyncdb for accurate storage of central reference data.
In contrast to the former three, #mnmsyncdb is not designed to receive direct user input; instead it is synced against the other databases.

Each database has all of the [[database/mirrors|mirrors]], and usually the data of the mirrors is consistent across databases (i.e. the `staging` flavor of one database is in `sync` with other `staging` mirrors).