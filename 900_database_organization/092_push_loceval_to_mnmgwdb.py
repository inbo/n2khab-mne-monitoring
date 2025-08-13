#!/usr/bin/env python3

# load news from `gwTransfer`
# also check for relocations; then append `Locations`, location_id, and grts_adress everywhere
# new locations can be captured from `Replacements`

# DONE [094_...] location_cells are not updated.
# DONE push the final replacement_data to server
# TODO there are duplicates.


import numpy as NP
import pandas as PD
import MNMDatabaseToolbox as DTB
import geopandas as GPD

# suffix = "-testing"
# suffix = "-staging"
suffix = ""

print("|"*64)
print(f"going to transfer data from *loceval{suffix}* to *mnmgwdb{suffix}*. \n")

### establish database connections
base_folder = DTB.PL.Path(".")

print(f"login to *loceval{suffix}*:")
loceval = DTB.ConnectDatabase(
    base_folder/"inbopostgis_server.conf",
    # connection_config = f"dumpall",
    # database = f"loceval{suffix}"
    connection_config = f"loceval{suffix}"
    # connection_config = f"loceval"
    )

print(f"login to *mnmgwdb{suffix}*:")
mnmgwdb = DTB.ConnectDatabase(
    base_folder/"inbopostgis_server.conf",
    connection_config = f"mnmgwdb{suffix}",
    )
# mnmgwdb.config["database"]

print("Thank you. Proceeding...")


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### find local replacements
#///////////////////////////////////////////////////////////////////////////////

query = """
SELECT
  CASE WHEN (NOT UNIT.is_replaced) AND (LOREP.grts_address_replacement) IS NULL
    THEN LOC.wkb_geometry
    ELSE LOREP.wkb_geometry
   END AS wkb_geometry,
  CASE WHEN (NOT UNIT.is_replaced) AND (LOREP.grts_address_replacement) IS NULL
    THEN UNIT.grts_address
    ELSE LOREP.grts_address_replacement
   END AS grts_address_replacement,
  CASE WHEN (NOT UNIT.is_replaced) AND (LOREP.grts_address_replacement) IS NULL
    THEN 0
    ELSE LOREP.replacement_rank
   END AS replacement_rank,
  LOREP.notes,
  UNIT.type,
  UNIT.grts_address,
  UNIT.location_id,
  UNIT.is_replaced
FROM "outbound"."SampleUnits" AS UNIT
LEFT JOIN "metadata"."Locations" AS LOC
  ON UNIT.location_id = LOC.location_id
LEFT JOIN (
  SELECT
    sampleunit_id,
    wkb_geometry,
    grts_address_replacement,
    replacement_rank,
    notes
  FROM "outbound"."Replacements"
  WHERE is_selected
  ) AS LOREP
  ON UNIT.sampleunit_id = LOREP.sampleunit_id
WHERE UNIT.grts_address IN (
  SELECT DISTINCT grts_address
  FROM "outbound"."Replacements" AS RP
  LEFT JOIN "outbound"."SampleUnits" AS SU
  ON SU.sampleunit_id = RP.sampleunit_id
  WHERE is_selected
  AND NOT is_inappropriate
  )
;
"""

# select the ones from `loceval` which indicate some replacement
replacement_data = GPD.read_postgis( \
    query, \
    con = loceval.connection, \
    geom_col = "wkb_geometry" \
    ).astype({"grts_address": int, "grts_address_replacement": int})
replacement_data.loc[
    replacement_data["grts_address"].values == 23238
    , :].T

# compare to the locations in `mnmgwdb`
existing_locations = GPD.read_postgis( \
    """SELECT * FROM "metadata"."Locations";""", \
    con = mnmgwdb.connection, \
    geom_col = "wkb_geometry" \
    ).astype({"grts_address": int})
existing_locations.loc[
    [any(int(val) == NP.array([23238, 6314694, 23091910]))
     for val in existing_locations["grts_address"].values
     ], :]

new_locations = replacement_data.loc[
    [int(grts_repl) not in existing_locations["grts_address"].values \
     for grts_repl in replacement_data["grts_address_replacement"].values],
    :
]
# print("\n".join(map(str, list(map(int, sorted(existing_locations["grts_address"].values))))))


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### Create New Locations
#///////////////////////////////////////////////////////////////////////////////

# query latest index values
ogc_counter = int(existing_locations["ogc_fid"].max())
lid_counter = int(existing_locations["location_id"].max())

# insert new locations into locations; retrieve location_id
# idx = 0; row = new_locations.iloc[0, :]

# data type cleanup
# TODO this is a bit helpless; geopandas seems to fail uploading wkb :/
clean_sqlstr = lambda txt: txt.replace("'", "")
val_to_geom_point = lambda val: "NULL" if PD.isna(val) else f"'{clean_sqlstr(str(val))}'"
val_to_int = lambda val: "NULL" if PD.isna(val) else str(int(val))


# we start by creating new locations
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

    DTB.ExecuteSQL(mnmgwdb, insert_command, verbose = True, test_dry = False)


if False:
    # note 20250813:
    # I do not know why this duplicate code chunk is here;
    #   cautiously de-activating it..

    # re-load {existing, new} locations after novel upload
    existing_locations = GPD.read_postgis( \
        """SELECT * FROM "metadata"."Locations";""", \
        con = mnmgwdb.connection, \
        geom_col = "wkb_geometry" \
        ).astype({"grts_address": int})

    new_locations = replacement_data.loc[
        [int(grts_repl) not in existing_locations["grts_address"].values \
         for grts_repl in replacement_data["grts_address"].values],
        :
     ]

    # we start by creating new locations
    for idx, row in new_locations.iterrows():
        geom_str = val_to_geom_point(row["wkb_geometry"])
        grts_new = val_to_int(row["grts_address"])
        ogc_counter += 1
        lid_counter += 1
        insert_command = f"""
            INSERT INTO "metadata"."Locations" (ogc_fid, location_id, wkb_geometry, grts_address)
            VALUES ({ogc_counter}, {lid_counter}, {geom_str}, {grts_new});
        """

        # print(insert_command)

        DTB.ExecuteSQL(mnmgwdb, insert_command, verbose = True, test_dry = False)



### intermediate cleaning up

## join the new, corrected location id to the list of replacements
# replacement_data["new_location_id"] = NP.nan
# replacement_data.drop("new_location_id", axis = 1, inplace = True)
existing_again = PD.read_sql( \
    """SELECT DISTINCT grts_address AS grts_address_replacement, location_id AS new_location_id
    FROM "metadata"."Locations"
    ;
    """, \
    con = mnmgwdb.connection, \
    index_col = "grts_address_replacement"
)

replacement_data = replacement_data.join(
    existing_again, \
    how = "left", \
    on = "grts_address_replacement"
)

replacement_data.loc[
    replacement_data["grts_address"].values == 23238
    , :].T

## also join samplelocation_id -> lookup to the SampleLocations

existing_samplelocations = PD.read_sql( \
    """SELECT DISTINCT grts_address, samplelocation_id, location_id AS location_id_current
    FROM "outbound"."SampleLocations"
    ;
    """, \
    con = mnmgwdb.connection \
)
# NOTE: some locations have been mis-replaced previously; their original GRTS is not stored (yet)

replacement_data["samplelocation_id"] = NP.nan

missing = []
# idx = 2
# row = replacement_data.iloc[idx, :]
for idx, row in replacement_data.iterrows():
    # first, check the grts_address_replacement
    found_existing = \
        existing_samplelocations["grts_address"].values \
            == int(row["grts_address_replacement"])


    # if that is not found, check whether instead the location appears in original grts
    if not any(found_existing):
        found_existing = \
            existing_samplelocations["grts_address"].values \
                == int(row["grts_address"])

    # ... assemble the ones not found
    if not any(found_existing):
        print(idx, row)
        missing.append(idx)
    else:
        # finally, if it was found, just store the identifier
        replacement_data.loc[idx, "samplelocation_id"] = \
            existing_samplelocations.loc[found_existing, "samplelocation_id"].values[0]

print(missing)
replacement_data.loc[
    replacement_data["grts_address"].values == 23238
    , :].T

## some of the sample location ids are recovered from the other replacements
missing_lookup = replacement_data.loc[:, ["grts_address", "samplelocation_id"]].dropna().drop_duplicates()
missing_lookup.set_index("grts_address", inplace = True)

for miss in missing:
    grts = replacement_data.loc[miss, "grts_address"]
    replacement_data.loc[miss, "samplelocation_id"] = \
        missing_lookup.loc[grts, "samplelocation_id"]

# (that data type issue again)
replacement_data["samplelocation_id"] = replacement_data["samplelocation_id"].astype(int)


# print(replacement_data.sample(3).T)
print(replacement_data.loc[replacement_data["grts_address"].values == 23238, :].T)


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### Update Dependent Tables
#///////////////////////////////////////////////////////////////////////////////

### replace the location_id and grts in other tables
# it is necessary to duplicate lines if strata of the same GRTS are moved to separate locations.

def DuplicateTableRow(
        db,
        schema,
        table_key,
        identifier_dict,
        index_columns,
        index_newvalues = None
    ):
    # schema = "outbound"
    # table_key = "SampleLocations"
    # identifier_dict = 312
    # samplelocation_id_new = None
    # samplelocation_id_new = samplelocation_next

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
        WHERE {identifier_string};
    """

    DTB.ExecuteSQL(db, insert_command, verbose = True, test_dry = False)


# SELECT * FROM "outbound"."SampleLocations" WHERE samplelocation_id = 667;
# DELETE FROM "outbound"."SampleLocations" CASCADE WHERE samplelocation_id = 667;
# DELETE FROM "outbound"."SampleLocations" CASCADE WHERE samplelocation_id = 668;
# SELECT * FROM "outbound"."SampleLocations" ORDER BY samplelocation_id DESC LIMIT 3;

# table_namestring = '"outbound"."SampleLocations"'
# grts_to_replace = 23238


### duplicate all lines of a split observation, based on samplelocation_id
# (everywhere, except on LocationInfos -> script 095_...)

replacement_data["new_samplelocation_id"] = replacement_data["samplelocation_id"]

unique_samplelocations = replacement_data.loc[:, ["grts_address", "samplelocation_id"]].drop_duplicates()


for _, potential_duplicates in unique_samplelocations.iterrows():
    # potential_duplicates = unique_samplelocations.loc[unique_samplelocations["grts_address"].values == 23238, :]
    # potential_duplicates = unique_samplelocations.loc[unique_samplelocations.loc[unique_samplelocations["grts_address"].values == 23238, :].index.values[-1], :]
    # potential_duplicates = unique_samplelocations.loc[unique_samplelocations.loc[unique_samplelocations["grts_address"].values == 17318, :].index.values[0], :]
    # potential_duplicates = unique_samplelocations.loc[unique_samplelocations.loc[unique_samplelocations["grts_address"].values == 23257, :].index.values[0], :]
    podup = potential_duplicates.to_dict()

    # find those replacements which share the same samplelocation
    replacements_with_same_samplelocation = replacement_data.loc[
        NP.logical_and(
            replacement_data["grts_address"].values == podup["grts_address"],
            replacement_data["samplelocation_id"].values == podup["samplelocation_id"]
            )
        , :]

    # do not loop if duplicate is already unique
    if replacements_with_same_samplelocation.shape[0] <= 1:
        # 20250801 !!! WAS <= 1 -> did I not replace the singles?!
        # 20250813 !!! reverted: why should I duplicate the unique SampleLocations?
        continue

    # store the originals to delete them later
    old_identifiers = []

    # duplicate_index = 5
    # duplicate = replacements_with_same_samplelocation.loc[duplicate_index]

    # ... but IF we find duplicates, all rows are adjusted.
    for duplicate_index, duplicate in replacements_with_same_samplelocation.iterrows():

        ## duplicate SampleLocation
        samplelocation_next = int(PD.read_sql(
            """
                SELECT samplelocation_id FROM "outbound"."SampleLocations"
                ORDER BY samplelocation_id DESC
                LIMIT 1;
            """,
            con = mnmgwdb.connection
           ).values[0, 0]) + 1

        old_samplelocation = int(duplicate["samplelocation_id"])
        new_grts = int(duplicate["grts_address_replacement"])
        new_strata = f"'{duplicate["type"]}'"
        new_locid = f'{duplicate["new_location_id"]}'


        DuplicateTableRow(
            db = mnmgwdb,
            schema = "outbound",
            table_key = "SampleLocations",
            identifier_dict = {"samplelocation_id": old_samplelocation},
            index_columns = ["grts_address", "samplelocation_id", "strata", "location_id"],
            index_newvalues = [new_grts, samplelocation_next, new_strata, new_locid]
           )
        # SELECT * FROM "outbound"."SampleLocations" WHERE location_id = 527;

        # store the right samplelocation_id for this replacement
        replacement_data.loc[duplicate_index, "new_samplelocation_id"] = samplelocation_next


        ## duplicate LocationInfos
        # -> moved to the 095 script


        ## duplicate FieldworkCalendar
        # ISSUE: there can be multiple entries.

        fwcal_subset = PD.read_sql(
            f"""
            SELECT DISTINCT fieldworkcalendar_id FROM "outbound"."FieldworkCalendar"
            WHERE samplelocation_id = {old_samplelocation};
            """,
            con = mnmgwdb.connection
           ).values.astype(int).ravel()

        if len(fwcal_subset) < 1:
            # there are replacements which do not have mnmgwdb calendar events yet.
            # They still need and identifier placeholder.
            old_identifiers.append({"samplelocation_id": old_samplelocation, "fieldworkcalendar_id": None})

        for fwcal_id in fwcal_subset:

            fwcal_next = int(PD.read_sql(
                """
                    SELECT fieldworkcalendar_id FROM "outbound"."FieldworkCalendar"
                    ORDER BY fieldworkcalendar_id DESC
                    LIMIT 1;
                """,
                con = mnmgwdb.connection
               ).values[0, 0]) + 1
            # DELETE FROM  "outbound"."FieldworkCalendar" WHERE fieldworkcalendar_id = 1192;


            DuplicateTableRow(
                db = mnmgwdb,
                schema = "outbound",
                table_key = "FieldworkCalendar",
                identifier_dict = {"samplelocation_id": old_samplelocation, "fieldworkcalendar_id": fwcal_id},
                index_columns = ["grts_address", "fieldworkcalendar_id", "samplelocation_id"],
                index_newvalues = [new_grts, fwcal_next, samplelocation_next]
               )


            ## duplicate Visits
            visit_next = int(PD.read_sql(
                """
                    SELECT visit_id FROM "inbound"."Visits"
                    ORDER BY visit_id DESC
                    LIMIT 1;
                """,
                con = mnmgwdb.connection
               ).values[0, 0]) + 1
            # DELETE FROM  "outbound"."FieldworkCalendar" WHERE fieldworkcalendar_id = 1192;
            # DELETE FROM  "outbound"."FieldworkCalendar" WHERE fieldworkcalendar_id = 1193;

            DuplicateTableRow(
                db = mnmgwdb,
                schema = "inbound",
                table_key = "Visits",
                identifier_dict = {"samplelocation_id": old_samplelocation, "fieldworkcalendar_id": fwcal_id},
                index_columns = ["grts_address", "fieldworkcalendar_id", "samplelocation_id", "visit_id", "location_id"],
                index_newvalues = [new_grts, fwcal_next, samplelocation_next, visit_next, new_locid]
               )


            # TODO !!!! ALTER TABLE "outbound"."FieldworkCalendar" DROP CONSTRAINT "FieldworkCalendar_pkey" CASCADE;
            # TODO !!!! ALTER TABLE "inbound"."Visits" DROP CONSTRAINT "Visits_pkey" CASCADE;
            # ... or maybe not!

            ## duplicate *Activities
            ## check if this is a WIA of CSA
            # activity_table  = "ChemicalSamplingActivities"
            for activity_table in ["WellInstallationActivities", "ChemicalSamplingActivities"]:
                check_query = f"""
                SELECT DISTINCT fieldwork_id FROM "inbound"."{activity_table}"
                WHERE TRUE
                  AND samplelocation_id = {old_samplelocation}
                  AND fieldworkcalendar_id = {fwcal_id}
                ;
                """
                activity_check = PD.read_sql( \
                    check_query, \
                    con = mnmgwdb.connection \
                )
                if activity_check.shape[0] == 0:
                    continue

                fieldwork_id = int(activity_check.iloc[0, 0])

                fieldwork_next = int(PD.read_sql(
                    """
                        SELECT fieldwork_id FROM "inbound"."FieldWork"
                        WHERE fieldwork_id IS NOT NULL
                        ORDER BY fieldwork_id DESC
                        LIMIT 1;
                    """,
                    con = mnmgwdb.connection
                   ).values[0, 0]) + 1

                DuplicateTableRow(
                    db = mnmgwdb,
                    schema = "inbound",
                    table_key = activity_table,
                    identifier_dict = {"fieldwork_id": fieldwork_id},
                    index_columns = ["fieldworkcalendar_id", "samplelocation_id", "visit_id", "fieldwork_id"],
                    index_newvalues = [fwcal_next, samplelocation_next, visit_next, fieldwork_next]
                   )

            old_identifiers.append({"samplelocation_id": old_samplelocation, "fieldworkcalendar_id": int(fwcal_id)})

        # SELECT DISTINCT fieldworkcalendar_id FROM "outbound"."FieldworkCalendar" WHERE samplelocation_id = 527 OR samplelocation_id = 667;

    # / loop duplicates

    ### DELETE rows by old identifiers
    obsolete_rows = PD.DataFrame.from_dict(old_identifiers).drop_duplicates()

    # print("#"*80)
    # print(potential_duplicates)
    # print(obsolete_rows)
    # print(replacement_data)

    for fwcal_id in NP.unique(obsolete_rows["fieldworkcalendar_id"].values):
        if fwcal_id is None:
            continue

        for table in [
                '"outbound"."FieldworkCalendar"',
                '"inbound"."Visits"',
                '"inbound"."WellInstallationActivities"',
                '"inbound"."ChemicalSamplingActivities"'
            ]:

            delete_command = f"""
                DELETE FROM {table} WHERE fieldworkcalendar_id = {int(fwcal_id)};
            """

            DTB.ExecuteSQL(mnmgwdb, delete_command, verbose = True, test_dry = False)

    for sloc_id in NP.unique(obsolete_rows["samplelocation_id"].values):
        for table in [
                '"outbound"."SampleLocations"',
                '"outbound"."FieldworkCalendar"',
                '"inbound"."Visits"'
            ]:

            delete_command = f"""
                DELETE FROM {table} WHERE samplelocation_id = {int(sloc_id)};
            """

            DTB.ExecuteSQL(mnmgwdb, delete_command, verbose = True, test_dry = False)

### store replacement_data on the server for reference

print(replacement_data)

delete_command = f"""
       DELETE FROM "archive"."ReplacementData";
   """
DTB.ExecuteSQL(mnmgwdb, delete_command, verbose = True, test_dry = False)

upload_cols = [
    'type',
    'grts_address',
    'grts_address_replacement',
    'is_replaced',
    'new_location_id',
    'new_samplelocation_id',
    'replacement_rank'
]
replacement_upload = replacement_data.loc[:, upload_cols]

# print(insert_command)
replacement_upload.to_sql( \
        "ReplacementData", \
        schema = "archive", \
        con = mnmgwdb.connection, \
        index = False, \
        if_exists = "append", \
        method = "multi" \
    )


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### transfer loceval
#///////////////////////////////////////////////////////////////////////////////
# i.e. move loceval info to the mnmgwdb database

transfer_data = PD.read_sql_table( \
        "gwTransfer", \
        schema = "outbound", \
        con = loceval.connection \
    ).astype({"grts_address": int, "grts_address_original": int})
transfer_data.loc[
    NP.logical_and(
        transfer_data["grts_address_original"].values == 23238,
        transfer_data["eval_source"].values == "loceval"
    ), :].T

# for replacements, correct sample location ids must be linked
samplelocations_lookup = PD.read_sql_table( \
        "SampleLocations", \
        schema = "outbound", \
        con = mnmgwdb.connection \
    ).loc[:, ["grts_address", "samplelocation_id", "strata"]] \
    .astype({"grts_address": int, "samplelocation_id": int}) \
    .set_index("grts_address", inplace = False)

samplelocations_lookup.loc[[23238, 6314694, 23091910], :].T
# TODO check duplicate grts in lookup

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

loceval_upload = loceval_joined.loc[
    NP.logical_not(PD.isna(loceval_joined["samplelocation_id"].values)),
    [col for col in loceval_joined.columns if col not in ["strata", "grts_address_original"]]] \
    .astype({"grts_address": int, "samplelocation_id": int})

print(loceval_upload.sample(3).T)

non_logged = PD.isna(loceval_upload["eval_name"].values)
print(loceval_upload.loc[non_logged, :].T)

loceval_upload.loc[non_logged, "eval_date"] = loceval_upload.loc[non_logged, "log_update"].dt.date
loceval_upload.loc[non_logged, "eval_name"] = loceval_upload.loc[non_logged, "log_user"]

delete_command = f"""
       DELETE FROM "outbound"."LocationEvaluations"
       WHERE TRUE;
   """
DTB.ExecuteSQL(mnmgwdb, delete_command, verbose = True, test_dry = False)

# print(insert_command)
loceval_upload.to_sql( \
    "LocationEvaluations", \
    schema = "outbound", \
    con = mnmgwdb.connection, \
    index = False, \
    if_exists = "append", \
    method = "multi" \
)



# SELECT * FROM "metadata"."Locations" WHERE grts_address = 23238 OR grts_address = 6314694 OR grts_address = 23091910;
# SELECT * FROM "outbound"."SampleLocations" WHERE is_replacement;
# SELECT * FROM "outbound"."SampleLocations" WHERE grts_address = 23238 OR grts_address = 6314694 OR grts_address = 23091910;
# SELECT DISTINCT fieldworkcalendar_id FROM "outbound"."FieldworkCalendar" WHERE samplelocation_id IN (SELECT DISTINCT samplelocation_id FROM "outbound"."SampleLocations" WHERE grts_address = 23238 OR grts_address = 6314694 OR grts_address = 23091910);
#
# SELECT * FROM "outbound"."FieldworkCalendar" AS CAL LEFT JOIN "archive"."ReplacementData" AS REP ON CAL.grts_address = REP.grts_address WHERE done_planning AND replacementdata_id IS NOT NULL;

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### transfer cell mapping
#///////////////////////////////////////////////////////////////////////////////
# i.e. move cell maps to the mnmgwdb database
# cell maps do not refer to grts or location indices,
# they are just freely drawn polygons, associated later by spatial proximity.

### CellMaps
cellmaps = GPD.read_postgis( \
    """SELECT * FROM "inbound"."CellMaps";""", \
    con = loceval.connection, \
    geom_col = "wkb_geometry" \
    )

delete_command = f"""
       DELETE FROM "outbound"."CellMaps"
       WHERE TRUE;
   """
DTB.ExecuteSQL(mnmgwdb, delete_command, verbose = True, test_dry = False)

# print(insert_command)
cellmaps.to_postgis( \
    "CellMaps", \
    schema = "outbound", \
    con = mnmgwdb.connection, \
    index = False, \
    if_exists = "append", \
)
