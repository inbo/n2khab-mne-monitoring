#!/usr/bin/env sh

# This is the personal test script of Falk.
# It moves to the database tooling server to run all the scripts which are due for daily database maintenance.
# They are tested on the `-staging` mirrors of databases.

set -e # stop on error

# work here
cd /data/git/n2khab-mne-monitoring_dbtools/900_database_organization

# sync the -staging mirrors
# sh yad/sync_staging.sh

Rscript 110_sync_FreeFieldNotes.R -staging # will often segfault on first attempt
Rscript 110_sync_FreeFieldNotes.R -staging
Rscript 110_sync_Trails.R -staging
Rscript 111_distribute_loceval_via_mnmsyncdb.R -staging
Rscript 112_fill_location_journals.R -staging
Rscript 114_replaced_LocationCells.R -staging
Rscript 115_sync_LocationInfos.R -staging
Rscript 116_update_wgs84_coordinates.R -staging
Rscript 117loceval_mhq_areas.R -staging
Rscript 117mnmgwdb_mhq_areas.R -staging
Rscript 117surfdb_mhq_areas.R -staging

## only on `production` - no testing required:
# Rscript 118_random_placementpoints_mnmgwdb.R -staging
# Rscript 119_random_elevationpoints_mnmgwdb.R -staging
