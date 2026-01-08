```sh
pg_dump -U <readonly_user> -h <host> -p <port> -d mnmgwdb -N tiger -N public -c > /tmp/mnmgwdb_db_dump.txt
psql -U <db_admin> -h <host> -p <port> -d mnmgwdb_staging -W < /tmp/mnmgwdb_db_dump.txt
rm /tmp/mnmgwdb_db_dump.txt
```
