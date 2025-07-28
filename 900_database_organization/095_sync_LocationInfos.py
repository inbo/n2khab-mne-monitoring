#!/usr/bin/env python3

# Testing:
#   UPDATE "outbound"."LocationInfos" SET accessibility_inaccessible = TRUE, log_update = current_timestamp WHERE locationinfo_id = 1;

import numpy as NP
import pandas as PD
import MNMDatabaseToolbox as DTB
import geopandas as GPD

# suffix = "-testing"
suffix = ""

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
# print(source_data.loc[source_data["grts_address"].values == 23238, :].T)


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
lookup_cols = ["grts_address", "grts_address_replacement"]
target_replacements = PD.read_sql( \
    query.format(schema = "archive", table = "ReplacementData"), \
    con = mnmgwdb.connection, \
).loc[:, lookup_cols]
replacement_lookup = target_replacements.drop_duplicates().sort_values(lookup_cols)


### apply lookup
## source
source_data = source_data \
    .join( \
        replacement_lookup.set_index("grts_address"),
        how = "left",
        on = "grts_address"
    )
source_data = source_data.reset_index(drop = True)
# source_data.loc[NP.logical_not(PD.isna(source_data["grts_address_replacement"])), :]
for idx, row in source_data.iterrows():
    grts_address_replacement = source_data.loc[idx, "grts_address_replacement"]
    if PD.isna(grts_address_replacement):
        source_data.loc[idx, "grts_address_replacement"] = source_data.loc[idx, "grts_address"]

source_data["grts_address_replacement"] = source_data["grts_address_replacement"].astype(int)
source_data = source_data.rename(columns = {"grts_address": "grts_address_original"})


## target
target_data.loc[target_data["grts_address"].values == 23238, :]

# outer = source_data.loc[:, ["grts_address"]] \
#     .merge(target_data.loc[:, ["grts_address"]], \
#            how='outer', indicator=True)
# source_grts_to_target = outer[(outer._merge=='left_only')].drop('_merge', axis=1)

# target_locations.loc[target_locations["grts_address"].values == 23238, :]
# target_locations
# target_data.columns
# target_data["grts_address_replacement"] = target_data["grts_address"].values
# target_data = target_data.drop(columns = "grts_address")
target_data = target_data.rename(columns = {"grts_address": "grts_address_replacement"})

target_data = target_data \
    .join( \
        replacement_lookup.set_index("grts_address_replacement"),
        how = "left",
        on = "grts_address_replacement"
    )

target_data = target_data.reset_index(drop = True)
# target_data.loc[NP.logical_not(PD.isna(target_data["grts_address_replacement"])), :]
for idx, row in target_data.iterrows():
    grts_address = target_data.loc[idx, "grts_address"]
    if PD.isna(grts_address):
        target_data.loc[idx, "grts_address"] = target_data.loc[idx, "grts_address_replacement"]

target_data["grts_address"] = target_data["grts_address"].astype(int)
target_data = target_data.rename(columns = {"grts_address": "grts_address_original"})


### associate data

# source_data.loc[:, ["locationinfo_id", "grts_address"]].sort_values("grts_address").to_csv("dumps/find_locationinfos.csv")
# source_data.loc[[int(grts) == 23238 for grts in source_data["grts_address"].values], :]
# target_data.loc[target_data["grts_address"].values == 6314694, :]
common_grts = source_data.loc[:, ["grts_address_original", "grts_address_replacement"]] \
    .merge(target_data.loc[:, ["grts_address_original", "grts_address_replacement"]], \
           how='inner', indicator=False)

missing_grts = source_data.loc[:, ["grts_address_original", "grts_address_replacement"]] \
    .merge(target_data.loc[:, ["grts_address_original", "grts_address_replacement"]], \
           how='outer', indicator=True)
missing_target = missing_grts[(missing_grts._merge=='left_only')].drop('_merge', axis=1)
missing_source = missing_grts[(missing_grts._merge=='right_only')].drop('_merge', axis=1)


source_data = source_data.set_index(["grts_address_original", "grts_address_replacement"])
target_data = target_data.set_index(["grts_address_original", "grts_address_replacement"])

source_new = target_data.loc[[missing_source.iloc[i, :] for i in range(missing_source.shape[0])], :]
target_new = source_data.loc[[missing_target.iloc[i, :] for i in range(missing_target.shape[0])], :]


source_new = source_new.reset_index(drop = False)
target_new = target_new.reset_index(drop = False)
common_columns = target_new.columns
source_new = source_new.loc[:, common_columns]
source_new = source_new.rename(columns = {"grts_address_original": "grts_address"}).drop(columns = "grts_address_replacement")
target_new = target_new.rename(columns = {"grts_address_replacement": "grts_address"}).drop(columns = "grts_address_original")
source_new = source_new.drop(columns = "locationinfo_id")
target_new = target_new.drop(columns = "locationinfo_id")

clean_sqlstr = lambda txt: txt.replace("'", "")
noop = lambda val: val
val_to_bool = lambda val: "NULL" if PD.isna(val) else ("TRUE" if bool(val) else "FALSE")
val_to_datetime = lambda val: "NULL" if PD.isna(val) else f"'{str(val)}'"
val_to_int = lambda val: "NULL" if PD.isna(val) else str(int(val))
val_to_string = lambda val: "NULL" if PD.isna(val) else f"'{clean_sqlstr(val)}'"

col_change_functions = {
    "grts_address": val_to_int,
    "log_creator": val_to_string,
    "log_creation": val_to_datetime,
    "log_user": val_to_string,
    "log_update": val_to_datetime,
    "landowner": val_to_string,
    "accessibility_inaccessible": val_to_bool,
    "accessibility_revisit": val_to_datetime,
    "recovery_hints": val_to_string,
    }


print("\\"*64)
print(f"Inserting new into **{loceval.config['database']}**:")
# insert_source = source_new.iloc[0, :]
for _, insert_source in source_new.iterrows():

    insert_value_dict = {k: col_change_functions.get(k, noop)(v)
        for k, v in insert_source.to_dict().items()}
    locationid_lookup_query = f"""
        SELECT DISTINCT location_id
        FROM "metadata"."Locations"
        WHERE grts_address = {insert_value_dict["grts_address"]}
        ;
    """
    locationid = PD.read_sql(
        locationid_lookup_query,
        con = loceval.connection
    ).iloc[0, 0]

    insert_value_dict["location_id"] = str(int(locationid))

    locationinfo_next = int(PD.read_sql(
        """
               SELECT locationinfo_id FROM "outbound"."LocationInfos"
               ORDER BY locationinfo_id DESC
               LIMIT 1;
           """,
        con = loceval.connection
       ).values[0, 0]) + 1
    insert_value_dict["locationinfo_id"] = str(int(locationinfo_next))

    insert_command = """
      INSERT INTO "outbound"."LocationInfos"
      ( locationinfo_id,
        log_creator, log_creation, log_user, log_update,
        location_id, grts_address,
        landowner, accessibility_inaccessible,
        accessibility_revisit, recovery_hints
      ) VALUES ( {locationinfo_id},
        {log_creator}, {log_creation}, {log_user}, {log_update},
        {location_id},{grts_address},
        {landowner},{accessibility_inaccessible},
        {accessibility_revisit}, {recovery_hints}
      );
    """.format(**insert_value_dict)
    # print(insert_command)
    DTB.ExecuteSQL(
        loceval,
        insert_command,
        verbose = True
       )


print("\\"*64)
print(f"Inserting new into **{mnmgwdb.config['database']}**:")
# insert_target = target_new.iloc[0, :]
for _, insert_target in target_new.iterrows():

    insert_value_dict = {k: col_change_functions.get(k, noop)(v)
        for k, v in insert_target.to_dict().items()}
    locationid_lookup_query = f"""
        SELECT DISTINCT location_id
        FROM "metadata"."Locations"
        WHERE grts_address = {insert_value_dict["grts_address"]}
        ;
    """
    locationid = PD.read_sql(
        locationid_lookup_query,
        con = mnmgwdb.connection
    ).iloc[0, 0]

    insert_value_dict["location_id"] = str(int(locationid))

    locationinfo_next = int(PD.read_sql(
        """
               SELECT locationinfo_id FROM "outbound"."LocationInfos"
               ORDER BY locationinfo_id DESC
               LIMIT 1;
           """,
        con = mnmgwdb.connection
       ).values[0, 0]) + 1
    insert_value_dict["locationinfo_id"] = str(int(locationinfo_next))

    insert_command = """
      INSERT INTO "outbound"."LocationInfos"
      ( locationinfo_id,
        log_creator, log_creation, log_user, log_update,
        location_id, grts_address,
        landowner, accessibility_inaccessible,
        accessibility_revisit, recovery_hints
      ) VALUES ( {locationinfo_id},
        {log_creator}, {log_creation}, {log_user}, {log_update},
        {location_id},{grts_address},
        {landowner},{accessibility_inaccessible},
        {accessibility_revisit}, {recovery_hints}
      );
    """.format(**insert_value_dict)
    # print(insert_command)
    DTB.ExecuteSQL(
        mnmgwdb,
        insert_command,
        verbose = True
       )


# only keep common grts (which *should* be all)
#

source_data = source_data.loc[[common_grts.iloc[i, :] for i in range(common_grts.shape[0])], :].reset_index(drop = False)
target_data = target_data.loc[[common_grts.iloc[i, :] for i in range(common_grts.shape[0])], :].reset_index(drop = False)

#perform outer join
accessibility_cols = [ \
    "grts_address_original", "grts_address_replacement",
    "accessibility_inaccessible", "accessibility_revisit",
    "recovery_hints"
   ]
outer = source_data.loc[:, accessibility_cols] \
    .merge(target_data.loc[:, accessibility_cols], \
           how='outer', indicator=True)
# print(outer)

source_to_target = outer[(outer._merge=='left_only')].drop('_merge', axis=1)
source_to_target = source_to_target.rename(columns = {"grts_address_replacement": "grts_address"}).drop(columns = "grts_address_original")
target_to_source = outer[(outer._merge=='right_only')].drop('_merge', axis=1)
target_to_source = target_to_source.rename(columns = {"grts_address_original": "grts_address"}).drop(columns = "grts_address_replacement")


def get_timestamp(df, grts, col):
    return(df.loc[df[col] == grts, "log_update"])

get_ts_source = lambda df, grts: get_timestamp(df, grts, "grts_address_replacement")
get_ts_target = lambda df, grts: get_timestamp(df, grts, "grts_address_original")



# if (source_to_target.shape[0] > 0):
source_to_target["source_ts"] = [get_ts_source(source_data, row["grts_address"]).values[0]
                                 for _, row in source_to_target.iterrows() ]

source_to_target["target_ts"] = [get_ts_source(target_data, row["grts_address"]).values[0]
                                 for _, row in source_to_target.iterrows() ]

# TODO if
# row = source_to_target.iloc[0, :]
target_to_source["source_ts"] = [get_ts_target(source_data, row["grts_address"]).values[0]
                                 for _, row in target_to_source.iterrows() ]

target_to_source["target_ts"] = [get_ts_target(target_data, row["grts_address"]).values[0]
                                 for _, row in target_to_source.iterrows() ]

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

### lookup (replacements)


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

### ARCHIVE
# I did some manual adjustments to avoid loosing previous entries (older than maintenance on other db)
# SELECT * FROM "outbound"."LocationInfos"
# WHERE grts_address =
# 23238
# ;
#
# UPDATE "outbound"."LocationInfos" SET accessibility_revisit = NULL WHERE grts_address =
# 23238
# ;
# 47238
# 905382
