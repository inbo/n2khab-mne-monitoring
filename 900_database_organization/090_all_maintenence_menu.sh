#!/usr/bin/env sh

MIRROR="$1"

source .dbinit/bin/activate
# Rscript 090_R_connect_background.R &

if [[ "$MIRROR" == "-staging" ]]; then
    sh ./yad/sync_staging.sh
fi

yad --form \
    --title="MNM Database Maintenance (mirror $MIRROR)" \
    --center \
    --text-align="left" \
    --text="<span font_weight='bold' font='14' color='#78c6dd'>Please select a maintenance task.</span> (mirror: $MIRROR)" \
    --columns=1 --align-buttons \
    --field="  mirror":fbtn "echo $MIRROR" \
    --field="  [loceval] -> [mnmgwdb]":fbtn            "python 091_push_loceval_to_mnmgwdb.py $MIRROR " \
    --field="  update FA-Calendar [mnmgwdb]":fbtn      "Rscript 092_update_facalendar.R $MIRROR " \
    --field="  update LocationCells [mnmgwdb]":fbtn    "Rscript 093_replaced_LocationCells.R $MIRROR " \
    --field="  sync LocationInfos":fbtn                "python 094_sync_LocationInfos.py $MIRROR " \
    --field="  re-link all keys":fbtn                  "Rscript 095_re_link_foreign_keys_optional.R $MIRROR " \
    --field="  update coordinates":fbtn                "Rscript 096_update_wgs84_coordinates.R $MIRROR " \
    --field="  mhq areas [loceval]":fbtn               "Rscript 097loceval_mhq_areas.R $MIRROR " \
    --field="  mhq areas [mnmgwdb]":fbtn               "Rscript 097mnmgwdb_mhq_areas.R $MIRROR " \
    --field="  random placement points [mnmgwdb]":fbtn "Rscript 098_random_placementpoints_mnmgwdb.R $MIRROR " \
    --field="  sync FreeFieldNotes":fbtn               "python 099_sync_FreeFieldNotes.py $MIRROR " \
    --button="Exit!gtk-cancel:1"
