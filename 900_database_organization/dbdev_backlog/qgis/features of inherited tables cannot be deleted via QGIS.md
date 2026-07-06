---
aliases:
  - minimal example and QGIS issue on deletion on inherited GIS tables
tags:
  - Observations
  - inheritance
  - qgis
  - primarykeys
started: 2026-07-06
finished:
execution:
status: false
---

issue opened with more details:
<https://github.com/qgis/QGIS/issues/66706>

temporary workaround: trivial views

## Observation
When [[timeline/2026-07-02|implementing Observations]], it became apparent that #QGIS disables feature deletion for tables which inherit the base class #Observations.
The underlying reason seems to be [that postgreSQL does not pass PK constraints via inheritance](https://www.postgresql.org/docs/current/ddl-inherit.html#DDL-INHERIT-CAVEATS): QGIS does not find a PK for the child table, and refuses to delete (for safety).

## Reproducible Example

### create database

### Fruits
```sql
SET standard_conforming_strings = ON;
DROP TABLE IF EXISTS fruits CASCADE;

BEGIN;
CREATE TABLE fruits();

COMMENT ON TABLE fruits IS E'interface -> common fields of all derived tables, but the table itself is not supposed to contain data';

ALTER TABLE fruits ADD COLUMN "ogc_fid" SERIAL CONSTRAINT "pk_fruits_fid" PRIMARY KEY;
SELECT AddGeometryColumn('fruits', 'wkb_geometry', 31370, 'POINT', 2);
CREATE INDEX "fruits_wkb_geometry_geom_idx" ON fruits USING GIST ("wkb_geometry");

GRANT USAGE ON SEQUENCE fruits_ogc_fid_seq TO testrole;
GRANT SELECT ON SEQUENCE fruits_ogc_fid_seq TO testrole;

ALTER TABLE fruits ADD COLUMN fruit_id int NOT NULL UNIQUE;
COMMENT ON COLUMN fruits.fruit_id IS E'a fruit index, shared across all kinds of fruits';

COMMIT;

-- sequence instead of true primary key because the ogc_fid goes first
CREATE SEQUENCE seq_fruit_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY fruits.fruit_id;
ALTER TABLE fruits ALTER COLUMN fruit_id
 SET DEFAULT nextval('seq_fruit_id'::regclass);

GRANT USAGE ON SEQUENCE seq_fruit_id TO testrole;
GRANT SELECT ON SEQUENCE seq_fruit_id TO testrole;

GRANT SELECT ON fruits TO testrole;
GRANT INSERT ON fruits TO testrole;
GRANT UPDATE ON fruits TO testrole;
GRANT DELETE ON fruits TO testrole;


```

### Bananas: Variant 1 (naïve -- fails)

```sql
SET standard_conforming_strings = ON;

DROP TABLE IF EXISTS bananas CASCADE;

BEGIN;
CREATE TABLE bananas()
INHERITS (fruits)
;

COMMENT ON TABLE bananas IS E'A non-abstract type of fruit, the table contains data.';

ALTER TABLE bananas ADD COLUMN banana_id int NOT NULL;
COMMENT ON COLUMN bananas.banana_id IS E'banana index (extra, on top of fruit_id)';

COMMIT;

-- sequence banana_id
CREATE SEQUENCE seq_banana_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY bananas.banana_id;
ALTER TABLE bananas ALTER COLUMN banana_id
 SET DEFAULT nextval('seq_banana_id'::regclass);

GRANT USAGE ON SEQUENCE seq_banana_id TO testrole;
GRANT SELECT ON SEQUENCE seq_banana_id TO testrole;

GRANT SELECT ON bananas TO testrole;
GRANT INSERT ON bananas TO testrole;
GRANT UPDATE ON bananas TO testrole;
GRANT DELETE ON bananas TO testrole;

```

### Bananas: Variant 2 (second #primarykey -- works but dangerous)

```sql
BEGIN;
CREATE TABLE bananas()
INHERITS (fruits)
;

COMMENT ON TABLE bananas IS E'A non-abstract type of fruit, the table contains data.';

ALTER TABLE bananas ADD COLUMN banana_id SERIAL CONSTRAINT "pk_bananas_fid" PRIMARY KEY;
COMMENT ON COLUMN bananas.banana_id IS E'banana index (extra, on top of fruit_id)';

GRANT USAGE ON SEQUENCE bananas_banana_id_seq TO testrole;
GRANT SELECT ON SEQUENCE bananas_banana_id_seq TO testrole;

COMMIT;


GRANT SELECT ON bananas TO testrole;
GRANT INSERT ON bananas TO testrole;
GRANT UPDATE ON bananas TO testrole;
GRANT DELETE ON bananas TO testrole;

```

This seems to work okay as long as nobody does [[manually insert an existing value for a primary key]]. 
But that is a bad idea anyways.

### workaround 5: Views (cumbersome)

```sql

DROP VIEW IF EXISTS see_bananas ;
CREATE VIEW see_bananas AS
SELECT *
FROM bananas ;

GRANT SELECT ON  see_bananas  TO testrole;
GRANT UPDATE ON  see_bananas  TO testrole;
GRANT DELETE ON  see_bananas  TO testrole;
GRANT INSERT ON  see_bananas  TO testrole;

```