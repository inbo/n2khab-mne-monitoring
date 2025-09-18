#!/usr/bin/env sh


source .dbinit/bin/activate.fish

python 091_push_loceval_to_mnmgwdb.py
# Rscript 092_update_facalendar.R #
Rscript 093_replaced_LocationCells.R
python 094_sync_LocationInfos.py
Rscript 095_re_link_foreign_keys_optional.R
Rscript 096_update_wgs84_coordinates.R
Rscript 097loceval_mhq_areas.R
Rscript 097mnmgwdb_mhq_areas.R
Rscript 098_random_placementpoints_mnmgwdb.R
python 099_sync_FreeFieldNotes.py
