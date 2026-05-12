---
aliases:
tags:
  - logging
  - sync_mod
  - triggers
started:
finished:
execution:
status: false
---

there is a `sync_mod` function which captures logging information (i.e. which user changed a db entry at what time).
```
CREATE FUNCTION "metadata".sync_mod() RETURNS trigger AS $sync_mod$
BEGIN
  NEW.log_update := current_timestamp;
  NEW.log_user := current_user;

  RETURN NEW
  ;
END;
```

This function should be conditional on `current_user` to avoid that technical table operations trigger it.
Rather urgent requirement since #mnmsyncdb [[draft and implement mnmsyncdb a database for synchronization of interchange data|implementation]].