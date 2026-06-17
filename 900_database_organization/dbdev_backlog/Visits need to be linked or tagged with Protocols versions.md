---
aliases:
  - time- and context-dependent links to Protocols
tags:
  - Protocols
  - Visits
started:
finished:
execution:
status: false
---

By now, #Protocols are associated with #Visits via #GroupedActivities.
This is a useful basic link; however, protocols will change over time and we must record the protocol version at the time of execution.

Rough concept:
+ introduce a `ProtocolVersions` (PV's) table which links to protocols, captures version changes with date, and might even store a changelog.
+ Then, `Visits` should directly link to PV's; choose sensible/dynamic defaults to facilitate entry for users (with the option to overwrite).