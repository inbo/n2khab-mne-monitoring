
Shell script to get data from one database to another (dump-restore technique).

> [!warning] Permissions
> This also copies user permissions and is therefore unsuited for transfer between [[database/mirrors|mirrors]] `staging`/`production` ("live" environments) and `testing`/`dev` ("testing" environment).

```sh
pg_dump -U <readonly_user> -h <host> -p <port> -d mnmgwdb -N tiger -N public -c > /tmp/mnmgwdb_db_dump.txt
psql -U <db_admin> -h <host> -p <port> -d mnmgwdb_staging -W < /tmp/mnmgwdb_db_dump.txt
rm /tmp/mnmgwdb_db_dump.txt
```


It is possible to copy only the content of all tables from one database mirror to another.
Detailed instructions and procedures can be found in `900_database_organization/930_copy_database.md`.