---
aliases:
tags:
  - mnmsyncdb
  - ReplacementData
  - LocationEvaluations
  - loceval
started:
finished:
execution:
status: false
---

- loceval info should be centrally pushed to #mnmsyncdb and then distributed to copies on user databases.via `111_push_loceval_to_***.R`
- [[consistent table and field names across databases]]
- part I: #ReplacementData 
- part II: #LocationEvaluations 

## migration plan
- new schema `transfer` in mnmsyncdb
- exapt `is_replaced` (*triv.*):
	- `is_replaced` column was trivially `TRUE` due to a filter in R `111_distribute_loceval_via_mnmsyncdb.R` 
	- grepped no other use of it 
	- -> field renamed to more meaningful `is_latest_replacement`
- add control columns:
	- `loceval_date` for uniqueness in case of repeated visits
	- `is_latest_replacement` as indication of the most relevant replacement

## structure
### steps
- on #mnmsyncdb: 
	- add schema `transfer`
	 - create table and derivatives
- on #mnmgwdb (and #mnmsurfdb via renew):
	- rename `grts_address` TO `grts_address_original`
	- rename `is_replaced` TO `is_latest_replacement`
	- add column `loceval_date` DEFAULT NULL (temporary)
	- drop column `new_location_id`
	- rename `new_samplelocation_id` TO `samplelocation_id`

- overhaul script `111`
	- purpose 1: move from `loceval` to `mnmsyncdb` with all necessary data aggregations
		- double check `ReplacementArchives`
	- purpose 2: distribute from sync to other user databases
		- column to fill upon distribution: `samplelocation_id`

### code mnmsyncdb
```sql
-- create schema
DROP SCHEMA IF EXISTS "transfer" CASCADE;
CREATE SCHEMA "transfer";
ALTER SCHEMA "transfer" OWNER TO <admin>;
GRANT USAGE ON SCHEMA "transfer" TO viewer_mnmdb;

-- create table
SET standard_conforming_strings = ON;
-- SET search_path TO pg_catalog,public,"transfer";

DROP TABLE IF EXISTS "transfer"."ReplacementData" CASCADE;
BEGIN;
CREATE TABLE "transfer"."ReplacementData"();
COMMENT ON TABLE "transfer"."ReplacementData" IS E'distribute info about local replacements (from `loceval`)';

ALTER TABLE "transfer"."ReplacementData" ADD COLUMN replacementdata_id int NOT NULL PRIMARY KEY; 
COMMENT ON COLUMN "transfer"."ReplacementData".replacementdata_id IS E'location info index (technical)';

ALTER TABLE "transfer"."ReplacementData" ADD COLUMN type varchar NOT NULL; 
COMMENT ON COLUMN "transfer"."ReplacementData".type IS E'type (code), our latest best assessment';

ALTER TABLE "transfer"."ReplacementData" ADD COLUMN grts_address_original int NOT NULL CHECK (grts_address_original > 0); 
COMMENT ON COLUMN "transfer"."ReplacementData".grts_address_original IS E'GRTS address (`original`, i.e. prior to replacements)';

ALTER TABLE "transfer"."ReplacementData" ADD COLUMN loceval_date date NOT NULL; 
COMMENT ON COLUMN "transfer"."ReplacementData".loceval_date IS E'date of the location evaluation';

ALTER TABLE "transfer"."ReplacementData" ADD COLUMN grts_address_replacement int NOT NULL CHECK (grts_address_replacement > 0); 
COMMENT ON COLUMN "transfer"."ReplacementData".grts_address_replacement IS E'GRTS address (`final`, i.e. after replacements)';

ALTER TABLE "transfer"."ReplacementData" ADD COLUMN replacement_rank smallint NOT NULL CHECK (replacement_rank >= 0); 
COMMENT ON COLUMN "transfer"."ReplacementData".replacement_rank IS E'replacement preference order, can be zero if original is retained for one type';

ALTER TABLE "transfer"."ReplacementData" ADD COLUMN is_latest_replacement boolean NOT NULL DEFAULT FALSE; 
COMMENT ON COLUMN "transfer"."ReplacementData".is_latest_replacement IS E'flag the latest and therefore most relevant replacement';

COMMIT;

-- sequence replacementdata_id
CREATE SEQUENCE "transfer".seq_replacementdata_id
INCREMENT BY 1
MINVALUE 0
MAXVALUE 2147483647
START WITH 1
CACHE 1
NO CYCLE
OWNED BY "transfer"."ReplacementData".replacementdata_id;
ALTER TABLE "transfer"."ReplacementData" ALTER COLUMN replacementdata_id
 SET DEFAULT nextval('transfer.seq_replacementdata_id'::regclass);

GRANT USAGE ON SEQUENCE "transfer"."seq_replacementdata_id" TO viewer_mnmdb;
GRANT SELECT ON SEQUENCE "transfer"."seq_replacementdata_id" TO viewer_mnmdb;

GRANT SELECT ON "transfer"."ReplacementData" TO viewer_mnmdb;

```


### code mnmgwdb
```sql
DROP SCHEMA IF EXISTS "transfer" CASCADE;
CREATE SCHEMA "transfer";
ALTER SCHEMA "transfer" OWNER TO <admin>;
GRANT USAGE ON SCHEMA "transfer" TO viewer_mnmdb;

ALTER TABLE "archive"."ReplacementData" SET SCHEMA "transfer"; 
-- ALTER SEQUENCE "archive".seq_replacementdata_id SET SCHEMA "transfer"; -- moved automatically

-- rename `grts_address` TO `grts_address_original`
ALTER TABLE "transfer"."ReplacementData" RENAME grts_address TO grts_address_original;

-- rename `is_replaced` TO `is_latest_replacement`
ALTER TABLE "transfer"."ReplacementData" RENAME is_replaced TO is_latest_replacement;

-- add column `loceval_date` with temporary DEFAULT NULL 
ALTER TABLE "transfer"."ReplacementData" ADD COLUMN loceval_date date DEFAULT NULL; 
COMMENT ON COLUMN "transfer"."ReplacementData".loceval_date IS E'date of the location evaluation';

-- rename `new_location_id` TO `location_id`
ALTER TABLE "transfer"."ReplacementData" DROP COLUMN new_location_id;

-- rename `new_samplelocation_id` TO `samplelocation_id`
ALTER TABLE "transfer"."ReplacementData" RENAME new_samplelocation_id TO samplelocation_id;

-- !!! renew Views which >>> grep -rni "ReplacementData" 

-- ### TODO for later:
-- ALTER TABLE "transfer"."ReplacementData" ALTER COLUMN loceval_date SET NOT NULL;

```


### archive
historic structure of #ReplacementData:
```sql
mnmgwdb=> \d "archive"."ReplacementData"
                                          Table "archive.ReplacementData"
          Column          |       Type        | Collation | Nullable |                   Default                   
--------------------------+-------------------+-----------+----------+---------------------------------------------
 replacementdata_id       | integer           |           | not null | nextval('seq_replacementdata_id'::regclass)
 type                     | character varying |           | not null | 
 grts_address             | integer           |           | not null | 
 grts_address_replacement | integer           |           | not null | 
 replacement_rank         | smallint          |           | not null | 
 is_replaced              | boolean           |           | not null | false
 new_location_id          | integer           |           | not null | 
 new_samplelocation_id    | integer           |           | not null | 
Indexes:
    "ReplacementData_pkey" PRIMARY KEY, btree (replacementdata_id)
```

## tooling / R code
- [x] reflect changes in `102_re_link_foreign_keys.R`
- [x] work on `111_distribute_loceval_via_mnmsyncdb.R`
	- [x] rename
	- [x] two step procedure: (i) `loceval` -> `mnmsyncdb`; (ii) `mnmsyncdb` -> *effectors*
	- [x] (i) `loceval` -> `mnmsyncdb`
	- [x] (ii) mnmsyncdb -> *effectors* (following previous, but functionalized and repeated)
		- [x] forward ReplacementData
		- [x] create new Locations and SampleUnits
		- [x] shift `grts_address` in all tables
		- [x] also push `LocationEvaluations` and `CellMaps`
		- [x] testing with actual data on `-staging` -> issues `mnmsurfdb`
- [ ] {?} are there other scripts affected?

[[handle historic entries in LocationJournals when a replacement is applied by 111_distribute_loceval_via_mnmsyncdb]]