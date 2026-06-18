-- view all kinds of Visits at once

CREATE VIEW "inbound"."AllVisits" AS
SELECT *
FROM ONLY "inbound"."Visits"
NATURAL FULL JOIN "inbound"."OtherVisits"
NATURAL FULL JOIN "inbound"."TerrestrialTypesVisits"
NATURAL FULL JOIN "inbound"."AquaticTypesVisits"
ORDER BY visit_id ASC
;


-- first, erase all default updating activities
CREATE RULE AllVisits_upd0 AS
ON UPDATE TO "inbound"."AllVisits"
DO INSTEAD NOTHING;


GRANT SELECT ON  "inbound"."AllVisits"  TO  viewer_mnmdb;
