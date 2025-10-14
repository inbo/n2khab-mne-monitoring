#!/usr/bin/env sh


source .dbinit/bin/activate.fish



[ ] python 091_push_loceval_to_mnmgwdb.py -staging
[ ] ??? Rscript 092_update_facalendar.R
[ ] Rscript 093_replaced_LocationCells.R
[ ] python 094_sync_LocationInfos.py
[ ] Rscript 095_re_link_foreign_keys_optional.R
[ ] Rscript 096_update_wgs84_coordinates.R
[ ] Rscript 097loceval_mhq_areas.R
[ ] Rscript 097mnmgwdb_mhq_areas.R
[ ] Rscript 098_random_placementpoints_mnmgwdb.R
[ ] python 099_sync_FreeFieldNotes.py

quarto render 040_consistency_dashboard.qmd --to html


to https://docs.google.com/spreadsheets/d/11_0sACvkvX_teOO_nJmTxYSV4-EzOWtxJYE1QNkStAc/edit
\COPY (
    SELECT samplelocation_id,
      location_id,
      grts_address,
      random_point_rank,
      compass,
      angle,
      angle_look,
      distance_m,
      lambert_lon,
      lambert_lat
    FROM "outbound"."RandomPoints"
    WHERE angle IS NOT NULL
    ORDER BY grts_address ASC, random_point_rank ASC
) TO '/data/mnm_db_backups/randompoints.csv' With CSV DELIMITER ',' HEADER
;



TODO: there is still an issue with orphaned SpecialActivities; e.g.

SELECT * FROM "inbound"."WellInstallationActivities"
SELECT * FROM "inbound"."ChemicalSamplingActivities"
WHERE grts_address = 437685 -> 8826293;


SELECT * FROM "archive"."ReplacementData"
WHERE grts_address = 53438326; # -> 57632630

SELECT * FROM "inbound"."ChemicalSamplingActivities"
SELECT * FROM "inbound"."WellInstallationActivities"
WHERE grts_address = 53438326;


TODO: location_infos don't get replaced; re-work 094 in R?
