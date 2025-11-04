alias:: system users, users, user
tags:: users

- *Disambiguation:* This is about server system users; for postgresql user roles, *cf.* [[database/authentication]]
- As is habit in linux, there is a "superuser" (`root`) to manage the system, and there are unprivileged regular users for basic work.
- basic principles:
	- the root user is not accessible from outside
	- no `sudo`/`doas` -> privilege escalation exclusively via root login
- A special system user is the `postgres` user to manage the [[database]].
	- It is locked, but can be accessed by first switching to root user, and successively switching to the database user:
	  ```sh
	  su - root
	  su - postgres
	  ```
	- This is needed for [[database/creation]] and to handle [user roles]([[database/authentication]]).