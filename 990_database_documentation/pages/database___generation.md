alias:: database/creation

- create database:
	- ssh to server
	- su to postgres (only works as root)
	- ```
	  createdb sandbox -O <db_superuser> --port <port>
	  ```
- [[software/postgis]] extension installation:
	- `psql` to database as owner
	- #+begin_src sql
	  CREATE EXTENSION postgis;
	  CREATE EXTENSION postgis_topology;
	  CREATE EXTENSION fuzzystrmatch;
	  CREATE EXTENSION postgis_tiger_geocoder;
	  #+end_src
- structure is stored in google sheets [here](https://drive.google.com/drive/folders/1zwyNuQEPcfK_CmT4OjrBeJGH9yrTrbGN?usp=drive_link)
	- `locevaldb`: https://docs.google.com/spreadsheets/d/12dWpyS2Wsjog3-z3q6-pUzlAnY4MuBbh6igDWH9bEZw/edit?usp=drive_link
	- `mnmgwdb`: https://docs.google.com/spreadsheets/d/1Xul9o8IVk4dtOXHVfxe680oyGP9EDM5dU20K9aiNhng/edit?usp=drive_link