-- view all kinds of Visits at once

CREATE VIEW "inbound"."AllVisits" AS
SELECT *
FROM ONLY "inbound"."Visits"
NATURAL FULL JOIN "inbound"."InstallationVisits"
NATURAL FULL JOIN "inbound"."SamplingVisits"
NATURAL FULL JOIN "inbound"."PositioningVisits"
NATURAL FULL JOIN "inbound"."OtherVisits"
ORDER BY visit_id ASC
;


-- remove all default updating activities
CREATE RULE AllVisits_upd0 AS
ON UPDATE TO "inbound"."AllVisits"
DO INSTEAD NOTHING;


GRANT SELECT ON  "inbound"."AllVisits"  TO  viewer_mnmdb;
