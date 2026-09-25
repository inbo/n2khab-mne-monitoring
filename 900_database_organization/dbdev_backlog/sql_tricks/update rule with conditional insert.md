---
aliases:
tags:
  - views
  - rules
---

Purpose of the example below is a #view which can optionally create a new feature in an associated table.
If the user enters data, and depending on the existence of corresponding entries in the associated table, two separate rules exist to either `INSERT` or `UPDATE`. 


## Basic Test

create a database for testing

```sh
# as `postgres` user
createdb sandbox -O <owner> --port <port>
psql -h <host> -p <port> -d sandbox -U <owner>
# dropdb sandbox -p <port>
```

table 1: visits (realistic, fake example)

```sql
DROP TABLE IF EXISTS visits;
CREATE TABLE visits (
  visit_id INT,
  link_observation BOOLEAN DEFAULT FALSE,
  grts_address INT NOT NULL,
  notes TEXT DEFAULT NULL
);

INSERT INTO visits (visit_id, grts_address)
VALUES
  ( 1, 20)
;
```

table 2: observations

```sql
DROP TABLE IF EXISTS observations;
CREATE TABLE observations (
  observation_id INT,
  visit_id INT DEFAULT NULL,
  grts_address INT DEFAULT NULL,
  notes TEXT DEFAULT NULL
);

CREATE SEQUENCE seq_observation_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY observations.observation_id;
ALTER TABLE observations ALTER COLUMN observation_id
 SET DEFAULT nextval('seq_observation_id'::regclass);

```

#view: fieldwork (combining info from visits and observations)

```sql
DROP VIEW IF EXISTS fieldwork CASCADE;
CREATE VIEW fieldwork AS
SELECT
  VIS.visit_id,
  VIS.grts_address,
  VIS.link_observation,
  VIS.notes AS visit_notes,
  OBS.observation_id,
  OBS.notes AS obs_notes
FROM visits AS VIS
LEFT JOIN observations AS OBS
  ON OBS.grts_address = VIS.grts_address
;

DROP RULE IF EXISTS fieldwork_upd0 ON fieldwork;
CREATE RULE fieldwork_upd0 AS
ON UPDATE TO fieldwork
DO INSTEAD NOTHING
;
```

update behavior is defined via update rules

> [!note] conditional rules
> Note the `ON UPDATE TO <table> WHERE <condition> DO` syntax
> which allows for case distinction and specific reaction (here: `INSERT` or `UPDATE`).

```sql
-- update visits (straight forward)
DROP RULE IF EXISTS fieldwork_upd_VIS ON fieldwork;
CREATE RULE fieldwork_upd_VIS AS
ON UPDATE TO fieldwork
DO ALSO
 UPDATE visits
 SET
   link_observation = NEW.link_observation,
   notes = NEW.visit_notes
   WHERE visit_id = OLD.visit_id
;


-- conditionally insert observation
DROP RULE IF EXISTS fieldwork_ins_OBS ON fieldwork;
CREATE RULE fieldwork_ins_OBS AS
ON UPDATE TO fieldwork
WHERE NEW.observation_id IS NULL
DO ALSO
 INSERT INTO observations (
  visit_id,
  grts_address,
  notes
 ) VALUES (
   NEW.visit_id,
   NEW.grts_address,
   NEW.obs_notes
 )
;

-- ... but update existing observations
DROP RULE IF EXISTS fieldwork_upd_OBS ON fieldwork;
CREATE RULE fieldwork_upd_OBS AS
ON UPDATE TO fieldwork
WHERE NEW.observation_id IS NOT NULL
DO ALSO
 UPDATE observations
 SET
   notes = NEW.obs_notes
WHERE
  observation_id = OLD.observation_id
  AND grts_address = OLD.grts_address
;

```

*The Test:* update the view, twice.
+ first time, a new observation is created
+ second time, the existing observation gets updated

```sql
SELECT * FROM fieldwork;

UPDATE fieldwork
SET visit_notes = 'test', obs_notes = 'test observation'
WHERE grts_address = 20;

UPDATE fieldwork
SET visit_notes = 'test 2', obs_notes = 'test observation 2'
WHERE grts_address = 20;
```


## Bonus: Geometry

Observations contain a (point) geometry, which is linked to the visit location in case of this creation 



```sql
-- delete all data
DELETE FROM visits;
DELETE FROM observations;

-- append geometry columns
ALTER TABLE visits ADD COLUMN "ogc_fid" SERIAL CONSTRAINT "pk_visits_fid" PRIMARY KEY;
SELECT AddGeometryColumn('public', 'visits', 'wkb_geometry', 31370, 'POINT', 2);
CREATE INDEX "visits_wkb_geometry_geom_idx" ON visits USING GIST ("wkb_geometry");


ALTER TABLE observations ADD COLUMN "ogc_fid" SERIAL CONSTRAINT "pk_observations_fid" PRIMARY KEY;
SELECT AddGeometryColumn('public', 'observations', 'wkb_geometry', 31370, 'POINT', 2);
CREATE INDEX "observations_wkb_geometry_geom_idx" ON observations USING GIST ("wkb_geometry");

-- insert an example geometry
INSERT INTO visits (visit_id, grts_address, wkb_geometry)
VALUES
  ( 1, 20, '01010000208A7A000050965CBCEC170241645B9EE8707E0641')
;

SELECT * FROM visits;
```

Adjusted view and update rules, now including and transferring geometry.

```sql

DROP VIEW IF EXISTS fieldwork CASCADE;
CREATE VIEW fieldwork AS
SELECT
  VIS.ogc_fid,
  VIS.wkb_geometry,
  VIS.visit_id,
  VIS.grts_address,
  VIS.link_observation,
  VIS.notes AS visit_notes,
  OBS.observation_id,
  OBS.notes AS obs_notes
FROM visits AS VIS
LEFT JOIN observations AS OBS
  ON OBS.grts_address = VIS.grts_address
;


DROP RULE IF EXISTS fieldwork_upd0 ON fieldwork;
CREATE RULE fieldwork_upd0 AS
ON UPDATE TO fieldwork
DO INSTEAD NOTHING
;


DROP RULE IF EXISTS fieldwork_upd_VIS ON fieldwork;
CREATE RULE fieldwork_upd_VIS AS
ON UPDATE TO fieldwork
DO ALSO
 UPDATE visits
 SET
   link_observation = NEW.link_observation,
   notes = NEW.visit_notes
   WHERE visit_id = OLD.visit_id
;


DROP RULE IF EXISTS fieldwork_ins_OBS ON fieldwork;
CREATE RULE fieldwork_ins_OBS AS
ON UPDATE TO fieldwork
WHERE NEW.observation_id IS NULL
DO ALSO
 INSERT INTO observations (
  visit_id,
  grts_address,
  notes,
  wkb_geometry
 ) VALUES (
   NEW.visit_id,
   NEW.grts_address,
   NEW.obs_notes,
   NEW.wkb_geometry
 )
;

DROP RULE IF EXISTS fieldwork_upd_OBS ON fieldwork;
CREATE RULE fieldwork_upd_OBS AS
ON UPDATE TO fieldwork
WHERE NEW.observation_id IS NOT NULL
DO ALSO
 UPDATE observations
 SET
   notes = NEW.obs_notes
WHERE
  observation_id = OLD.observation_id
  AND grts_address = OLD.grts_address
;

```

Same test as above:

```sql

SELECT * FROM fieldwork;

UPDATE fieldwork
SET visit_notes = 'test', obs_notes = 'test observation'
WHERE grts_address = 20;

SELECT * FROM observations;

UPDATE fieldwork
SET visit_notes = 'test 2', obs_notes = 'test observation 2'
WHERE grts_address = 20;

```

> [!success] Success!


# References
... helped me to get the syntax right:
+ https://stackoverflow.com/a/69972497
+ https://postgrespro.com/docs/postgresql/17/rules-update
