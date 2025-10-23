#!/usr/bin/env sh

MIRROR="$1"

source .dbinit/bin/activate
# Rscript 090_R_connect_background.R &

# if [[ "$MIRROR" == "-staging" ]]; then
#   sh ./yad/sync_staging.sh
# fi
sh ./yad/sync_staging.sh

yad --form \
  --title="MNM Database Maintenance (mirror $MIRROR)" \
  --center \
  --text-align="left" \
  --text="<span font_weight='bold' font='14' color='#78c6dd'>Please select a maintenance task.</span>" \
  --columns=3 --align-buttons \
  --field="  staging":fbtn "echo '-staging'" \
  --field=" {staging} [loceval] -> [mnmgwdb]":fbtn "python 091_push_loceval_to_mnmgwdb.py -staging " \
  --field=" {staging} update FA-Calendar [mnmgwdb]":fbtn "Rscript 092_update_facalendar.R -staging " \
  --field=" {staging} update LocationCells [mnmgwdb]":fbtn "Rscript 093_replaced_LocationCells.R -staging " \
  --field=" {staging} sync LocationInfos":fbtn "python 094_sync_LocationInfos.py -staging " \
  --field=" {staging} re-link all keys":fbtn "Rscript 095_re_link_foreign_keys_optional.R -staging " \
  --field=" {staging} update coordinates":fbtn "Rscript 096_update_wgs84_coordinates.R -staging " \
  --field=" {staging} mhq areas [loceval]":fbtn "Rscript 097loceval_mhq_areas.R -staging " \
  --field=" {staging} mhq areas [mnmgwdb]":fbtn "Rscript 097mnmgwdb_mhq_areas.R -staging " \
  --field=" {staging} random placement points [mnmgwdb]":fbtn "Rscript 098_random_placementpoints_mnmgwdb.R -staging " \
  --field=" {staging} sync FreeFieldNotes":fbtn "python 099_sync_FreeFieldNotes.py -staging " \
  --field=" render consistency dashboard [loceval]":fbtn "quarto render 040l_loceval_consistency_dashboard.qmd --to html" \
  --field=" render consistency dashboard [mnmgwdb]":fbtn "quarto render 040m_mnmgwdb_consistency_dashboard.qmd --to html" \
  --field="  mirror [$MIRROR]":fbtn "echo $MIRROR" \
  --field=" [loceval$MIRROR] -> [mnmgwdb$MIRROR]":fbtn "python 091_push_loceval_to_mnmgwdb.py $MIRROR " \
  --field=" update FA-Calendar [mnmgwdb$MIRROR]":fbtn "Rscript 092_update_facalendar.R $MIRROR " \
  --field=" update LocationCells [mnmgwdb$MIRROR]":fbtn "Rscript 093_replaced_LocationCells.R $MIRROR " \
  --field=" sync LocationInfos [$MIRROR]":fbtn "python 094_sync_LocationInfos.py $MIRROR " \
  --field=" re-link all keys [$MIRROR]":fbtn "Rscript 095_re_link_foreign_keys_optional.R $MIRROR " \
  --field=" update coordinates [$MIRROR]":fbtn "Rscript 096_update_wgs84_coordinates.R $MIRROR " \
  --field=" mhq areas [loceval$MIRROR]":fbtn "Rscript 097loceval_mhq_areas.R $MIRROR " \
  --field=" mhq areas [mnmgwdb$MIRROR]":fbtn "Rscript 097mnmgwdb_mhq_areas.R $MIRROR " \
  --field=" random placement points [mnmgwdb$MIRROR]":fbtn "Rscript 098_random_placementpoints_mnmgwdb.R $MIRROR " \
  --field=" sync FreeFieldNotes [$MIRROR]":fbtn "python 099_sync_FreeFieldNotes.py $MIRROR " \
  --field=" open dashboard [loceval]":fbtn "lynx 040l_loceval_consistency_dashboard.html" \
  --field=" open dashboard [mnmgwdb]":fbtn "lynx 040m_mnmgwdb_consistency_dashboard.html" \
  --field="":CHK FALSE \
  --field="":CHK FALSE \
  --field="":CHK FALSE \
  --field="":CHK FALSE \
  --field="":CHK FALSE \
  --field="":CHK FALSE \
  --field="":CHK FALSE \
  --field="":CHK FALSE \
  --field="":CHK FALSE \
  --field="":CHK FALSE \
  --field="":CHK FALSE \
  --field="":CHK FALSE \
  --field="":CHK FALSE \
  --button="Exit!gtk-cancel:1"
