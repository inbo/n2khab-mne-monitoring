---
aliases:
  - psql
  - psql terminal client
  - postgresql command line interface
tags:
  - postgres
  - terminal
  - cli
---
The most elementary, yet most powerful tool to interact with the database is the command line interface (`cli`).
It can be accessed via the `psql` command, which requires additional parameters to connect:

```sh
psql -h <host> -p <port> -d <database> -U <user>
```

When connecting to the server via this command, one can enter #query's or issue [[sql/backslash commands|backslash commands]] to receive information from the database.
Exporting data to files is possible via the [[sql/copy|copy]] command.

Because the `cli` is the fallback option for database connection (most IDE's just build on top of it), the [[sql/examples|examples]] in this documentation are usually working well on the command line.