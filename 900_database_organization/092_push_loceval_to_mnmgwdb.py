#!/usr/bin/env python3

# load news from `gwTransfer`
# also check for relocations; then append `Locations`, location_id, and grts_adress everywhere
# new locations can be captured from `Replacements`

# TODO location_cells are not updated.


import numpy as NP
import pandas as PD
import MNMDatabaseToolbox as DTB
import geopandas as GPD

suffix = "-testing"
suffix = ""

base_folder = DTB.PL.Path(".")

loceval = DTB.ConnectDatabase(
    base_folder/"inbopostgis_server.conf",
    connection_config = f"dumpall",
    database = f"loceval{suffix}"
    )

mnmgwdb = DTB.ConnectDatabase(
    base_folder/"inbopostgis_server.conf",
    connection_config = f"mnmgwdb{suffix}",
    )
# mnmgwdb.config["database"]


transfer_data = PD.read_sql_table( \
        "gwTransfer", \
        schema = "outbound", \
        con = loceval.connection \
    ).astype({"grts_address": int})
samplelocations_lookup = PD.read_sql_table( \
        "SampleLocations", \
        schema = "outbound", \
        con = mnmgwdb.connection \
    ).loc[:, ["grts_address", "samplelocation_id"]] \
    .astype({"grts_address": int, "samplelocation_id": int}) \
    .set_index("grts_address", inplace = False)

# before we upload, we need to collect all locations
loceval_joined = transfer_data \
    .join(
        samplelocations_lookup, \
        how = "left", \
        on = "grts_address"
    )


loceval_nolocations = loceval_joined.loc[
    PD.isna(loceval_joined["samplelocation_id"].values),
    :]
# TODO dump!!

loceval_upload = loceval_joined.loc[
    NP.logical_not(PD.isna(loceval_joined["samplelocation_id"].values)),
    :] \
    .astype({"grts_address": int, "samplelocation_id": int})

print(loceval_upload.sample(3).T)

delete_command = f"""
       DELETE FROM "outbound"."LocationEvaluations"
       WHERE TRUE;
   """
DTB.ExecuteSQL(mnmgwdb, delete_command, verbose = True)

# print(insert_command)
loceval_upload.to_sql( \
    "LocationEvaluations", \
    schema = "outbound", \
    con = mnmgwdb.connection, \
    index = False, \
    if_exists = "append", \
    method = "multi" \
)

# important: these are not relocated!


### relocate local replacements

query = """
SELECT
  LOREP.wkb_geometry,
  UNIT.grts_address,
  UNIT.location_id,
  LOREP.grts_address_replacement,
  LOREP.replacement_rank,
  LOREP.notes
FROM "outbound"."SampleUnits" AS UNIT
LEFT JOIN "outbound"."Replacements" AS LOREP
  ON UNIT.sampleunit_id = LOREP.sampleunit_id
WHERE UNIT.is_replaced
  AND LOREP.is_selected
  AND NOT LOREP.is_inappropriate
;
"""

replacement_data = GPD.read_postgis( \
    query, \
    con = loceval.connection, \
    geom_col = "wkb_geometry" \
    ).astype({"grts_address": int, "grts_address_replacement": int})



existing_locations = GPD.read_postgis( \
    """SELECT * FROM "metadata"."Locations";""", \
    con = mnmgwdb.connection, \
    geom_col = "wkb_geometry" \
    ).astype({"grts_address": int})

new_locations = replacement_data.loc[
    [int(grts_repl) not in existing_locations["grts_address"].values \
     for grts_repl in replacement_data["grts_address_replacement"].values],
    :
]

ogc_counter = int(existing_locations["ogc_fid"].max())
lid_counter = int(existing_locations["location_id"].max())

# insert new locations into locations; retrieve location_id
# idx = 0; row = new_locations.iloc[0, :]

clean_sqlstr = lambda txt: txt.replace("'", "")

# TODO this is a bit helpless; geopandas seems to fail uploading wkb :/
val_to_geom_point = lambda val: "NULL" if PD.isna(val) else f"'{clean_sqlstr(str(val))}'"
val_to_int = lambda val: "NULL" if PD.isna(val) else str(int(val))


for idx, row in new_locations.iterrows():
    geom_str = val_to_geom_point(row["wkb_geometry"])
    grts_new = val_to_int(row["grts_address_replacement"])
    ogc_counter += 1
    lid_counter += 1
    insert_command = f"""
        INSERT INTO "metadata"."Locations" (ogc_fid, location_id, wkb_geometry, grts_address)
        VALUES ({ogc_counter}, {lid_counter}, {geom_str}, {grts_new});
    """

    # print(insert_command)

    DTB.ExecuteSQL(mnmgwdb, insert_command, verbose = True)




### intermediate cleaning up
# DELETE FROM "metadata"."Locations" WHERE location_id = 667;
# DELETE FROM "metadata"."Locations" WHERE location_id = 668;
# DELETE FROM "metadata"."Locations" WHERE location_id = 669;
# DELETE FROM "metadata"."Locations" WHERE location_id = 1352;


# replacement_data["new_location_id"] = NP.nan
# replacement_data.drop("new_location_id", axis = 1, inplace = True)
existing_again = PD.read_sql( \
    """SELECT DISTINCT grts_address AS grts_address_replacement, location_id AS new_location_id
    FROM "metadata"."Locations";
    """, \
    con = mnmgwdb.connection, \
    index_col = "grts_address_replacement"
)

replacement_data = replacement_data.join(
    existing_again, \
    how = "left", \
    on = "grts_address_replacement"
)

print(replacement_data.sample(3).T)

### replace the location_id and grts in other tables

location_reference_list = {
    '"outbound"."SampleLocations"': {'grts': True, 'location_id': True},
    '"outbound"."FieldworkCalendar"': {'grts': True, 'location_id': False},
    '"inbound"."Visits"': {'grts': True, 'location_id': True},
    '"outbound"."LocationInfos"': {'grts': True, 'location_id': True},
    '"outbound"."LocationEvaluations"': {'grts': True, 'location_id': False}
}


for table_namestring, has_columns in location_reference_list.items():
    has_grts = has_columns['grts']
    has_location_id = has_columns['location_id']

    if has_grts:
        for idx, row in replacement_data.iterrows():
            grts_old = val_to_int(row["grts_address"])
            grts_new = val_to_int(row["grts_address_replacement"])
            if grts_old == grts_new:
                continue
            update_command = f"""
                UPDATE {table_namestring}
                SET grts_address = {grts_new}
                WHERE grts_address = {grts_old};
            """

            # print(update_command)
            DTB.ExecuteSQL(mnmgwdb, update_command, verbose = True)


    if has_location_id:
        for idx, row in replacement_data.iterrows():
            location_old = val_to_int(row["location_id"])
            location_new = val_to_int(row["new_location_id"])
            if location_old == location_new:
                continue
            update_command = f"""
                UPDATE {table_namestring}
                SET location_id = {location_new}
                WHERE location_id = {location_old};
            """

            # print(update_command)

            DTB.ExecuteSQL(mnmgwdb, update_command, verbose = True)


