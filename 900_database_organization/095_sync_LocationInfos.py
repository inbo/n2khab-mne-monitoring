#!/usr/bin/env python3

# Testing:
#   UPDATE "outbound"."LocationInfos" SET accessibility_inaccessible = TRUE, log_update = current_timestamp WHERE locationinfo_id = 1;

#  ALTER TABLE "outbound"."LocationInfos" DROP CONSTRAINT "LocationInfos_pkey" CASCADE;
#
#
#


import numpy as NP
import pandas as PD
import MNMDatabaseToolbox as DTB
import geopandas as GPD

# suffix = "-testing"
# suffix = "-staging"
suffix = ""

print("|"*64)
print(f"going to sync LocationInfos between *loceval{suffix}* and *mnmgwdb{suffix}*. \n")

base_folder = DTB.PL.Path(".")

print(f"login to *loceval{suffix}*:")
loceval = DTB.ConnectDatabase(
    base_folder/"inbopostgis_server.conf",
    connection_config = f"loceval{suffix}"
    )

print(f"login to *mnmgwdb{suffix}*:")
mnmgwdb = DTB.ConnectDatabase(
    base_folder/"inbopostgis_server.conf",
    connection_config = f"mnmgwdb{suffix}"
    )

print("Thank you. Proceeding...")


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### load data
#///////////////////////////////////////////////////////////////////////////////

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


### link replacements
lookup_cols = ["grts_address", "grts_address_replacement"]
target_replacements = PD.read_sql( \
    query.format(schema = "archive", table = "ReplacementData"), \
    con = mnmgwdb.connection, \
)
# replacement_lookup = target_replacements.loc[:, lookup_cols] \
#     .drop_duplicates() \
#     .sort_values(lookup_cols)


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### Replacements in Loceval
#///////////////////////////////////////////////////////////////////////////////
target_grts = set(target_data["grts_address"].values)
source_grts = set(source_data["grts_address"].values)
# print(list(sorted(map(int, source_grts))))
replacement_grts = set(target_replacements["grts_address_replacement"].values)

source_missing_grts = list(replacement_grts - source_grts)
target_missing_grts = list(replacement_grts - target_grts)
# TODO ignoring the latter for now: either fully replaced, or not scheduled yet

def DuplicateTableRow(
        db,
        schema,
        table_key,
        identifier_dict,
        index_columns,
        index_newvalues = None,
        one_unique_line = False
    ):
    # db = loceval
    # schema = "outbound"
    # table_key = "LocationInfos"
    # identifier_dict = {"grts_address": 51429121}
    # index_columns = ["locationinfo_id", "grts_address"]
    # index_newvalues = [latest_locinfo_id, 48897]

    print(f"duplicating {identifier_dict} ==> {list(zip(index_columns, index_newvalues))}.")

    table_namestring = f'"{schema}"."{table_key}"'
    existing_data = PD.read_sql(f"""
        SELECT * FROM {table_namestring};
        """,
        con = db.connection
    )

    if index_newvalues is None:
        index_newvalues = \
            [int(existing_data[icol].max()) + 1 for icol in index_columns]
    index_newstring = ", ".join( map(str, index_newvalues))

    columns = [col for col in existing_data.columns
               if col not in index_columns]

    columnstring = ", ".join(columns)

    identifier_string = " AND ".join(
        [f"{idcol} = {idval}" for idcol, idval in identifier_dict.items()]
        )

    insert_command = f"""
        INSERT INTO {table_namestring} ({", ".join(index_columns)}, {columnstring})
        SELECT {index_newstring}, {columnstring}
        FROM {table_namestring}
        WHERE {identifier_string}
    """
    if one_unique_line:
        insert_command += f"""
        ORDER BY log_update DESC, {", ".join(index_columns)}
        LIMIT 1
        """
    insert_command += f"""
        ;
    """

    DTB.ExecuteSQL(db, insert_command, verbose = True, test_dry = False)

### duplicate rows in source
source_infos_to_duplicate = target_replacements.loc[
    [grts in source_missing_grts
     for grts in target_replacements["grts_address_replacement"].values
     ], ["grts_address", "type", "grts_address_replacement"]] \
    .astype({"grts_address": int, "grts_address_replacement": int}) \
    .set_index("grts_address_replacement", inplace = False)


# latest_locinfo_id = int(PD.read_sql(
#     """
#     SELECT locationinfo_id FROM "outbound"."LocationInfos"
#     ORDER BY locationinfo_id DESC
#     LIMIT 1;
#     """,
#     con = loceval.connection
#    ).values[0, 0]) + 0
latest_ogc_fid = source_locations["ogc_fid"].max()
latest_location_id = source_locations["location_id"].max()
latest_locinfo_id = source_data["locationinfo_id"].max()

clean_sqlstr = lambda txt: txt.replace("'", "")
val_to_geom_point = lambda val: "NULL" if PD.isna(val) else f"'{clean_sqlstr(str(val))}'"

for grts_new, row in source_infos_to_duplicate.iterrows():
    # grts_new = source_infos_to_duplicate.index.values[0]
    # row = source_infos_to_duplicate.iloc[0, :]
    grts_old = row["grts_address"]
    # print(grts_old, grts_new)

    latest_ogc_fid += 1
    latest_location_id += 1
    latest_locinfo_id += 1

    # on loceval, there can be new grts (replacement) which also require a Location
    location_id = source_locations.loc[
        grts_new == source_locations['grts_address'].values,
        'location_id']
    if len(location_id) == 0:
        geom_str = val_to_geom_point(source_locations.loc[
            source_locations['grts_address'].values == grts_old,
            "wkb_geometry"].values[0])

        insert_command = f"""
            INSERT INTO "metadata"."Locations" (ogc_fid, location_id, wkb_geometry, grts_address)
            VALUES ({latest_ogc_fid}, {latest_location_id}, {geom_str}, {grts_new});
        """
        DTB.ExecuteSQL(loceval, insert_command, verbose = True, test_dry = False)

        location_id = latest_location_id
    else:
        location_id = int(location_id.values[0])

    DuplicateTableRow(
        db = loceval,
        schema = "outbound",
        table_key = "LocationInfos",
        identifier_dict = {"grts_address": grts_old},
        index_columns = ["grts_address", "locationinfo_id", "location_id"],
        index_newvalues = [grts_new, latest_locinfo_id, location_id]
       )



### duplicate rows in target
target_infos_to_duplicate = target_replacements.loc[
    [grts in target_missing_grts
     for grts in target_replacements["grts_address_replacement"].values
     ], ["grts_address", "type", "grts_address_replacement"]] \
    .astype({"grts_address": int, "grts_address_replacement": int}) \
    .set_index("grts_address_replacement", inplace = False)


latest_locinfo_id = target_data["locationinfo_id"].max()

for grts_new, row in target_infos_to_duplicate.iterrows():
    # grts_new = source_infos_to_duplicate.index.values[0]
    # row = source_infos_to_duplicate.iloc[0, :]
    grts_old = row["grts_address"]
    # print(grts_old, grts_new)

    latest_locinfo_id += 1

    DuplicateTableRow(
        db = mnmgwdb,
        schema = "outbound",
        table_key = "LocationInfos",
        identifier_dict = {"grts_address": grts_old},
        index_columns = ["grts_address", "locationinfo_id"],
        index_newvalues = [grts_new, latest_locinfo_id]
       )


# in target, if the replacement is complete,
# there is no need to keep the outdated association with the old Location

detached_infos = f"""
DELETE
FROM "outbound"."LocationInfos"
WHERE locationinfo_id NOT IN (
  SELECT DISTINCT locationinfo_id
  FROM "outbound"."LocationInfos" INFOS, "metadata"."Locations" LOCS
  WHERE INFOS.grts_address = LOCS.grts_address
    AND INFOS.location_id = LOCS.location_id
)
;
"""

DTB.ExecuteSQL(mnmgwdb, detached_infos, verbose = True, test_dry = False)


# Duplication is only useful

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### Match LocationInfos
#///////////////////////////////////////////////////////////////////////////////

# re-load source and target data
source_data = PD.read_sql_table( \
    "LocationInfos", \
    schema = "outbound", \
    con = loceval.connection \
)


target_data = PD.read_sql_table( \
    "LocationInfos", \
    schema = "outbound", \
    con = mnmgwdb.connection \
)

### apply lookup
## source
# source_data = source_data \
#     .join( \
#         replacement_lookup.set_index("grts_address"),
#         how = "left",
#         on = "grts_address"
#     )
# source_data = source_data.reset_index(drop = True)

# source_data.loc[NP.logical_not(PD.isna(source_data["grts_address_replacement"])), :]
# for idx, row in source_data.iterrows():
#     grts_address_replacement = source_data.loc[idx, "grts_address_replacement"]
#     if PD.isna(grts_address_replacement):
#         source_data.loc[idx, "grts_address_replacement"] = source_data.loc[idx, "grts_address"]
#
# source_data["grts_address_replacement"] = source_data["grts_address_replacement"].astype(int)
# source_data = source_data.rename(columns = {"grts_address": "grts_address_original"})


## target
# target_data.loc[target_data["grts_address"].values == 23238, :]

# outer = source_data.loc[:, ["grts_address"]] \
#     .merge(target_data.loc[:, ["grts_address"]], \
#            how='outer', indicator=True)
# source_grts_to_target = outer[(outer._merge=='left_only')].drop('_merge', axis=1)

# target_locations.loc[target_locations["grts_address"].values == 23238, :]
# target_locations
# target_data.columns
# target_data["grts_address_replacement"] = target_data["grts_address"].values
# target_data = target_data.drop(columns = "grts_address")
# target_data = target_data.rename(columns = {"grts_address": "grts_address_replacement"})

# !!!!!
# target_data = target_data \
#     .join( \
#         replacement_lookup.set_index("grts_address_replacement"),
#         how = "left",
#         on = "grts_address_replacement"
#     )

# target_data = target_data.reset_index(drop = True)
# # target_data.loc[NP.logical_not(PD.isna(target_data["grts_address_replacement"])), :]
# for idx, row in target_data.iterrows():
#     grts_address = target_data.loc[idx, "grts_address"]
#     if PD.isna(grts_address):
#         target_data.loc[idx, "grts_address"] = target_data.loc[idx, "grts_address_replacement"]

# target_data["grts_address"] = target_data["grts_address"].astype(int)
# target_data = target_data.rename(columns = {"grts_address": "grts_address_original"})


### associate data

# source_data.loc[:, ["locationinfo_id", "grts_address"]].sort_values("grts_address").to_csv("dumps/find_locationinfos.csv")
# source_data.loc[[int(grts) == 23238 for grts in source_data["grts_address"].values], :]
# target_data.loc[target_data["grts_address"].values == 6314694, :]
common_grts = source_data.loc[:, ["grts_address"]] \
    .merge(target_data.loc[:, ["grts_address"]], \
           how='inner', indicator=False)

missing_grts = source_data.loc[:, ["grts_address"]] \
    .merge(target_data.loc[:, ["grts_address"]], \
           how='outer', indicator=True)
missing_target = missing_grts[(missing_grts._merge=='left_only')].drop('_merge', axis=1)
missing_source = missing_grts[(missing_grts._merge=='right_only')].drop('_merge', axis=1)


source_data = source_data.set_index(["grts_address"])
target_data = target_data.set_index(["grts_address"])

# source_new = target_data.loc[[missing_source.iloc[i, :] for i in range(missing_source.shape[0])], :]
# target_new = source_data.loc[[missing_target.iloc[i, :] for i in range(missing_target.shape[0])], :]
source_new = target_data.loc[missing_source["grts_address"].values, :]
target_new = source_data.loc[missing_target["grts_address"].values, :]


source_new = source_new.reset_index(drop = False)
target_new = target_new.reset_index(drop = False)

# some columns are mnmgwdb only (e.g. watina code)
common_columns = list(set(target_new.columns).intersection(set(source_new.columns)))
source_new = source_new.loc[:, common_columns]
# source_new = source_new.rename(columns = {"grts_address_original": "grts_address"}).drop(columns = "grts_address_replacement")
target_new = target_new.loc[:, common_columns]
# target_new = target_new.rename(columns = {"grts_address_replacement": "grts_address"}).drop(columns = "grts_address_original")
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
    )
    if NP.multiply(*locationid.shape) == 0:
        print(f"""GRTS address not found in {loceval.config["database"]}::"metadata"."Locations": {insert_value_dict["grts_address"]}""")
        continue

    locationid = locationid.iloc[0, 0]

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
        {location_id}, {grts_address},
        {landowner}, {accessibility_inaccessible},
        {accessibility_revisit}, {recovery_hints}
      );
    """.format(**insert_value_dict)
    # print(insert_command)
    DTB.ExecuteSQL(
        loceval,
        insert_command,
        verbose = True
       )


print("...done." + "\n"*3)
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
    )
    if NP.multiply(*locationid.shape) == 0:
        print(f"""GRTS address not found in {mnmgwdb.config["database"]}::"metadata"."Locations": {insert_value_dict["grts_address"]}""")
        continue

    locationid = locationid.iloc[0, 0]

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
        {location_id}, {grts_address},
        {landowner}, {accessibility_inaccessible},
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

# source_data = source_data.loc[[common_grts.iloc[i, :] for i in range(common_grts.shape[0])], :].reset_index(drop = False)
# target_data = target_data.loc[[common_grts.iloc[i, :] for i in range(common_grts.shape[0])], :].reset_index(drop = False)
source_data = source_data.loc[common_grts["grts_address"].values, :].reset_index(drop = False)
target_data = target_data.loc[common_grts["grts_address"].values, :].reset_index(drop = False)

#perform outer join
accessibility_cols = [ \
    "grts_address",
    "accessibility_inaccessible", "accessibility_revisit",
    "recovery_hints"
   ]
outer = source_data.loc[:, accessibility_cols] \
    .merge(target_data.loc[:, accessibility_cols], \
           how='outer', indicator=True)
# print(outer)

source_to_target = outer[(outer._merge=='left_only')].drop('_merge', axis=1)
# source_to_target = source_to_target.rename(columns = {"grts_address_replacement": "grts_address"}).drop(columns = "grts_address_original")
target_to_source = outer[(outer._merge=='right_only')].drop('_merge', axis=1)
# target_to_source = target_to_source.rename(columns = {"grts_address_original": "grts_address"}).drop(columns = "grts_address_replacement")


def get_timestamp(df, grts, col):
    return(df.loc[df[col] == grts, "log_update"])

get_ts_source = lambda df, grts: get_timestamp(df, grts, "grts_address")
get_ts_target = lambda df, grts: get_timestamp(df, grts, "grts_address")



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

print("...done." + "\n"*3)
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

print("...done." + "\n"*3)
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

print("...done." + "\n"*3)
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
