
DROP VIEW IF EXISTS  "outbound"."LocationCoords";
CREATE VIEW "outbound"."LocationCoords" AS
SELECT
  LOC.*,
  COORDS.coordinate_id,
  COORDS.wgs84_x,
  COORDS.wgs84_y,
  COORDS.lambert_x,
  COORDS.lambert_y,
  '<a href="https://www.google.com/maps/place/' ||
    CAST(COORDS.wgs84_y AS VARCHAR) ||
    ',' ||
    CAST(COORDS.wgs84_x AS VARCHAR) ||
    '"> google </a>, <br><br> ' ||
  '<a href="https://www.openstreetmap.org/?mlat=' ||
    CAST(COORDS.wgs84_y AS VARCHAR) ||
    '&mlon=' ||
    CAST(COORDS.wgs84_x AS VARCHAR) ||
    '"> openstreetmap </a>, <br><br> ' ||
  '<a href="https://waze.com/ul?ll=' ||
    CAST(COORDS.wgs84_y AS VARCHAR) ||
    ',' ||
    CAST(COORDS.wgs84_x AS VARCHAR) ||
    '"> waze </a>'
    AS google_link
FROM "metadata"."Locations" AS LOC
LEFT JOIN "metadata"."Coordinates" AS COORDS
  ON COORDS.location_id = LOC.location_id
WHERE LOC.location_id IS NOT NULL
  AND COORDS.location_id IS NOT NULL
;

GRANT SELECT ON  "outbound"."LocationCoords"  TO  tom,yglinga,jens,lise,wouter,floris,karen,ward;
