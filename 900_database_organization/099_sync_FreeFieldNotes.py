#!/usr/bin/env python3

# TODO This is rough and edgy, but works for now. Will generalize later.

import sys as SYS
import numpy as NP
import pandas as PD
import MNMDatabaseToolbox as DTB
import geopandas as GPD


commandline_args = SYS.argv
if len(commandline_args) > 1:
    suffix = commandline_args[1]
else:
  suffix = ""
  # suffix = "-testing"
  # suffix = "-staging"


base_folder = DTB.PL.Path(".")

loceval = DTB.ConnectDatabase(
    base_folder/"inbopostgis_server.conf",
    connection_config = f"loceval{suffix}"
    )

mnmgwdb = DTB.ConnectDatabase(
    base_folder/"inbopostgis_server.conf",
    connection_config = f"mnmgwdb{suffix}"
    )
# mnmgwdb.config["database"]

query = """
    SELECT *
    FROM "{schema:s}"."{table:s}";
"""

source_data = GPD.read_postgis( \
    query.format(schema = "inbound", table = "FreeFieldNotes"), \
    con = loceval.connection, \
    geom_col = "wkb_geometry" \
    )
# print(source_data.sample(3).T)
source_data["teammember_id"]# .astype(NP.int64)

source_data.drop(["ogc_fid", "fieldnote_id"], axis = 1, inplace = True)
# source_data["wkb_geometry"] = source_data["wkb_geometry"].to_wkb(hex = True)

target_data = GPD.read_postgis( \
    query.format(schema = "inbound", table = "FreeFieldNotes"), \
    con = mnmgwdb.connection, \
    geom_col = "wkb_geometry" \
    )
# print(target_data.sample(1).T)
# target_data["teammember_id"].astype(NP.int64)
# TODO data types must match; might be issues if one does not have teammember_id

target_data.drop(["ogc_fid", "fieldnote_id"], axis = 1, inplace = True)
# target_data["wkb_geometry"] = target_data["wkb_geometry"].to_wkb(hex = True)


# def anti_join(df1, df2):
#perform outer join
outer = source_data.merge(target_data, how='outer', indicator=True)
# print(outer)

source_to_target = outer[(outer._merge=='left_only')].drop('_merge', axis=1)
target_to_source = outer[(outer._merge=='right_only')].drop('_merge', axis=1)


### lookup teammember
source_ref = PD.read_sql_table("TeamMembers", schema = "metadata", con = loceval.connection) \
             .loc[:, ["teammember_id", "username"]]
target_ref = PD.read_sql_table("TeamMembers", schema = "metadata", con = mnmgwdb.connection) \
             .loc[:, ["username", "teammember_id"]]

teammember_lookup = {
    row["teammember_id"]: row["teammember_id_target"]
    for _, row in source_ref.join( \
        target_ref, \
        how = "left", \
        lsuffix = "", \
        rsuffix = "_target" \
    ).iterrows() \
}
teammember_lookup_inverted = {v:k for k,v in teammember_lookup.items()}

# apply lookup
source_to_target["teammember_id"] = [
    teammember_lookup[tmid]
    for tmid in source_to_target["teammember_id"].values
]

target_to_source["teammember_id"] = [
    teammember_lookup_inverted[tmid]
    for tmid in target_to_source["teammember_id"].values
]


### TODO also lookup activity
# TODO BUT some don't exist -> convert to label?


### upload
# source_to_target.to_postgis( \
#     "FreeFieldNotes", \
#     schema = "inbound", \
#     con = mnmgwdb.connection, \
#     index = False, \
#     if_exists = "append" \
# )
#
clean_sqlstr = lambda txt: txt.replace("'", "")

# TODO this is a bit helpless; geopandas seems to fail uploading wkb :/

val_to_geom_point = lambda val: "NULL" if PD.isna(val) else f"'{clean_sqlstr(str(val))}'"
val_to_string = lambda val: "NULL" if PD.isna(val) else f"E'{clean_sqlstr(val)}'"
val_to_datetime = lambda val: "NULL" if PD.isna(val) else f"'{str(val)}'"
val_to_bool = lambda val: "NULL" if PD.isna(val) else ("TRUE" if bool(val) else "FALSE")
val_to_int = lambda val: "NULL" if PD.isna(val) else str(int(val))
noop = lambda val: val

col_change_functions = {
    "wkb_geometry": val_to_geom_point,
    "log_creator": val_to_string,
    "log_creation": val_to_datetime,
    "log_user": val_to_string,
    "log_update": val_to_datetime,
    "hide": val_to_bool,
    "teammember_id": val_to_int,
    "field_note": val_to_string,
    "note_date": val_to_datetime,
    "location": val_to_string,
    "activity": val_to_int,
    "photo": val_to_string,
    "audio": val_to_string
   }



def upload(df, to_connection):

    print(df)

    if df.shape[0] == 0:
        print("no rows to insert.")
        return

    insert_command = """
        INSERT INTO "inbound"."FreeFieldNotes" ({cols:s})
        VALUES ({vals:s});
    """

    # , "fieldnote_id"
    # df.dtypes
    # df.columns

    upload_to_target = df.copy()

    # upload_to_target = target_to_source.copy()
    for col in upload_to_target.columns:
        upload_to_target[col] = \
            [col_change_functions.get(col, noop)(val) \
             for val in df[col].values]


    existing_data = GPD.read_postgis( \
            """ SELECT * FROM "inbound"."FreeFieldNotes";""", \
            con = to_connection.connection, \
            geom_col = "wkb_geometry" \
        ) \
        .loc[:, ["ogc_fid", "fieldnote_id"]] \
        .astype(int)

    if existing_data.shape[0] > 0:
        ogc_counter = int(existing_data["ogc_fid"].max())
        ffnid_counter = int(existing_data["fieldnote_id"].max())
    else:
        ogc_counter = int(1)
        ffnid_counter = int(1)

    nrows = upload_to_target.shape[0]

    upload_to_target['ogc_fid'] = list(map(str, ogc_counter + NP.arange(nrows) + 1))
    upload_to_target['fieldnote_id'] = list(map(str, ffnid_counter + NP.arange(nrows) + 1))

    # upload_to_target.dtypes
    row_string = [", ".join(row) for i, row in upload_to_target.iterrows()]

    cols = ", ".join([col for col in upload_to_target.columns])
    vals = "),\n(".join(row_string)


    DTB.ExecuteSQL(
        to_connection,
        insert_command.format(cols = cols, vals = vals),
        verbose = True
       )

    # reset pk counter
    DTB.ExecuteSQL(
        to_connection,
        """
        SELECT setval(
          '"inbound".seq_fieldnote_id',
          (SELECT MAX(fieldnote_id) FROM "inbound"."FreeFieldNotes")
        );
        """,
        verbose = True
       )


print("/"*64)
print(f"Uploading from **{loceval.config['database']}** to **{mnmgwdb.config['database']}**:")
upload(source_to_target, to_connection = mnmgwdb)

print("\\"*64)
print(f"Uploading from **{mnmgwdb.config['database']}** to **{loceval.config['database']}**:")
upload(target_to_source, to_connection = loceval)
