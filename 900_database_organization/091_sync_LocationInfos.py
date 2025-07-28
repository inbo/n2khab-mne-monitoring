#!/usr/bin/env python3

# Testing:
#   UPDATE "outbound"."LocationInfos" SET accessibility_inaccessible = TRUE, log_update = current_timestamp WHERE locationinfo_id = 1;

import numpy as NP
import pandas as PD
import MNMDatabaseToolbox as DTB
import geopandas as GPD

suffix = "-testing"
# suffix = ""

base_folder = DTB.PL.Path(".")

loceval = DTB.ConnectDatabase(
    base_folder/"inbopostgis_server.conf",
    connection_config = f"loceval{suffix}"
    )

mnmgwdb = DTB.ConnectDatabase(
    base_folder/"inbopostgis_server.conf",
    connection_config = f"mnmgwdb{suffix}"
    )


query = """
    SELECT *
    FROM "{schema:s}"."{table:s}";
"""
# print(query.format(schema = "metadata", table = "LocationInfos"))


### source
source_locations = GPD.read_postgis( \
    query.format(schema = "metadata", table = "Locations"), \
    con = loceval.connection, \
    geom_col = "wkb_geometry" \
)

source_data = PD.read_sql_table( \
    "LocationInfos", \
    schema = "outbound", \
    con = loceval.connection \
)

# print(source_data.sample(3).T)


### target
target_locations = GPD.read_postgis( \
    query.format(schema = "metadata", table = "Locations"), \
    con = mnmgwdb.connection, \
    geom_col = "wkb_geometry" \
)

target_data = PD.read_sql_table( \
    "LocationInfos", \
    schema = "outbound", \
    con = mnmgwdb.connection \
)

# print(target_data.sample(3).T)


### link replacments
target_replacements = PD.read_sql_table( \
    query.format(schema = "archive", table = "ReplacementData"), \
    con = mnmgwdb.connection, \
)



### associate data
common_grts = source_data.loc[:, ["grts_address"]] \
    .merge(target_data.loc[:, ["grts_address"]], \
           how='inner', indicator=False).values.ravel()

# only keep common grts (which *should* be all)
source_data = source_data.loc[[grts in common_grts for grts in source_data["grts_address"].values], :]
target_data = target_data.loc[[grts in common_grts for grts in target_data["grts_address"].values], :]

#perform outer join
accessibility_cols = ["grts_address", "accessibility_inaccessible", "accessibility_revisit", "recovery_hints"]
outer = source_data.loc[:, accessibility_cols] \
    .merge(target_data.loc[:, accessibility_cols], \
           how='outer', indicator=True)
# print(outer)

source_to_target = outer[(outer._merge=='left_only')].drop('_merge', axis=1)
target_to_source = outer[(outer._merge=='right_only')].drop('_merge', axis=1)

def get_timestamp(df, grts):
    return(df.loc[df["grts_address"] == grts, "log_update"])

# if (source_to_target.shape[0] > 0):
source_to_target["source_ts"] = [get_timestamp(source_data, row["grts_address"]).values[0]
                                 for _, row in source_to_target.iterrows() ]

source_to_target["target_ts"] = [get_timestamp(target_data, row["grts_address"]).values[0]
                                 for _, row in source_to_target.iterrows() ]

# TODO if
# row = source_to_target.iloc[0, :]
target_to_source["source_ts"] = [get_timestamp(source_data, row["grts_address"]).values[0]
                                 for _, row in source_to_target.iterrows() ]

target_to_source["target_ts"] = [get_timestamp(target_data, row["grts_address"]).values[0]
                                 for _, row in source_to_target.iterrows() ]

## filter
source_to_target = source_to_target.loc[
    NP.logical_and(
        NP.logical_not(PD.isna(source_to_target["target_ts"].values)),
        source_to_target["target_ts"].values < source_to_target["source_ts"].values
    )
    , :]


target_to_source = target_to_source.loc[
    NP.logical_and(
        NP.logical_not(PD.isna(target_to_source["target_ts"].values)),
        target_to_source["target_ts"].values > target_to_source["source_ts"].values
    )
    , :]


### create update strings
clean_sqlstr = lambda txt: txt.replace("'", "")

noop = lambda val: val
val_to_bool = lambda val: "NULL" if PD.isna(val) else ("TRUE" if bool(val) else "FALSE")
val_to_datetime = lambda val: "NULL" if PD.isna(val) else f"'{str(val)}'"
val_to_int = lambda val: "NULL" if PD.isna(val) else str(int(val))
val_to_string = lambda val: "NULL" if PD.isna(val) else f"E'{clean_sqlstr(val)}'"

col_change_functions = {
    "accessibility_inaccessible": val_to_bool,
    "accessibility_revisit": val_to_datetime,
    "recovery_hints": val_to_string,
    "grts_address": val_to_int
    }


update_command = """
    UPDATE "outbound"."LocationInfos"
    SET accessibility_inaccessible = {accessibility_inaccessible},
        accessibility_revisit = {accessibility_revisit},
        recovery_hints = {recovery_hints}
    WHERE grts_address = {grts_address};
"""

print("/"*64)
print(f"Uploading from **{loceval.config['database']}** to **{mnmgwdb.config['database']}**:")
for _, row in source_to_target.iterrows():
    update_value_dict = {k: col_change_functions.get(k, noop)(v)
        for k, v in row.to_dict().items()}

    DTB.ExecuteSQL(
        mnmgwdb,
        update_command.format(**update_value_dict),
        verbose = True
       )

print("\\"*64)
print(f"Uploading from **{mnmgwdb.config['database']}** to **{loceval.config['database']}**:")
for _, row in target_to_source.iterrows():
    update_value_dict = {k: col_change_functions.get(k, noop)(v)
        for k, v in row.to_dict().items()}

    DTB.ExecuteSQL(
        loceval,
        update_command.format(**update_value_dict),
        verbose = True
       )


# TODO there is some potential here for using temporary tables and `UPDATE... SET... FROM... WHERE...;` script.
