ALTER TABLE "outbound"."RandomPoints" ADD COLUMN lambert_lon double precision;
COMMENT ON COLUMN "outbound"."RandomPoints".lambert_lon IS E'Lambert coord, longitude';

ALTER TABLE "outbound"."RandomPoints" ADD COLUMN lambert_lat double precision;
COMMENT ON COLUMN "outbound"."RandomPoints".lambert_lat IS E'Lambert coord, latitude';
