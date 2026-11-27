

CREATE TABLE "archive"."ObsoleteObservations2026Q4"
AS SELECT *
  FROM "inbound"."GeoObservations" GEO
NATURAL FULL JOIN "inbound"."TerraBioObservations" TERRA
NATURAL FULL JOIN "inbound"."AquaBioObservations" AQUA
NATURAL FULL JOIN "inbound"."LanduseObservations" LAND
;

GRANT SELECT ON "archive"."ObsoleteObservations2026Q4" TO viewer_mnmdb;


DROP TABLE IF EXISTS "inbound"."GeoObservations";
DROP TABLE IF EXISTS "inbound"."TerraBioObservations";
DROP TABLE IF EXISTS "inbound"."AquaBioObservations";
DROP TABLE IF EXISTS "inbound"."LanduseObservations";
