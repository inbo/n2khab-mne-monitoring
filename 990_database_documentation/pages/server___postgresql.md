alias:: software/postgresql, postgresql, postgres, psql

- https://wiki.archlinux.org/title/PostgreSQL
- Note that `su - postgres` only works as root
  ```
  su - postgres
  initdb --locale=C.UTF-8 --encoding=UTF8 -D /var/lib/postgres/data --data-checksums
  ```
- > vim /var/lib/postgres/data/postgresql.conf
  ```
  listen_addresses = '<host>'
  port = <port>
  ```
- > vim /var/lib/postgres/data/pg_hba.conf
	- ```sh
	  # IPv4 remote connections:
	  # TYPE  DATABASE        USER             ADDRESS         METHOD
	  host    all             all              <host>/32       scram-sha-256
	  host    all             <readonly_user>  <remote-ip>/32  scram-sha-256
	  host    mnmgwdb_testing tester           <remote-ip/0    scram-sha-256
	  host    all             <user1>,<user2>  0.0.0.0/0       scram-sha-256
	  ```
- #+begin_src sh
  systemctl start postgresql.service
  systemctl enable postgresql.service
  systemctl status postgresql.service
  #+end_src