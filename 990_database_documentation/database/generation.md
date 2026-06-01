---
aliases:
  - database/creation
---

create database:
- ssh to server
- su to postgres (only works as root)
- `createdb sandbox -O <db_superuser> --port <port>`

[[software/postgis|postgis]] extension installation:
- `psql` to database as owner
- ```sh
	CREATE EXTENSION postgis;
	CREATE EXTENSION postgis_topology;
	CREATE EXTENSION fuzzystrmatch;
	CREATE EXTENSION postgis_tiger_geocoder;
  ```


structure is stored in google sheets [here](https://drive.google.com/drive/folders/1zwyNuQEPcfK_CmT4OjrBeJGH9yrTrbGN?usp=drive_link)

- `mnmsyncdb`: <https://docs.google.com/spreadsheets/d/12bfwcqFFSiE9tHZUFzDteHLnDpT1NArGvJbS2FLUvk0/edit?usp=sharing>
- `locevaldb`: <https://docs.google.com/spreadsheets/d/12dWpyS2Wsjog3-z3q6-pUzlAnY4MuBbh6igDWH9bEZw/edit?usp=drive_link>
- `mnmgwdb`: <https://docs.google.com/spreadsheets/d/1Xul9o8IVk4dtOXHVfxe680oyGP9EDM5dU20K9aiNhng/edit?usp=drive_link>
- `mnmsurfdb`: <https://docs.google.com/spreadsheets/d/1STZ4o7WgREUeiMaml2VGtzm0D1IdQsqCieyTrVmsKGA/edit?usp=sharing>

Those structure sheets must be downloaded as `*.ods` file and converted to `csv` structure files via `ODStoCSVs(infile, outfolder)` in `MNMDatabaseToolbox.py`