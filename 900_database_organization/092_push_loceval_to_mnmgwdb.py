#!/usr/bin/env python3

# load news from `gwTransfer`
# also check for relocations; then append `Locations`, location_id, and grts_adress everywhere
# new locations can be captured from `Replacements`

# TODO location_cells are not updated.

        # TODO !!!! ALTER TABLE "outbound"."FieldworkCalendar" DROP CONSTRAINT "FieldworkCalendar_pkey" CASCADE;
        # TODO !!!! ALTER TABLE "inbound"."Visits" DROP CONSTRAINT "Visits_pkey" CASCADE;

import numpy as NP
import pandas as PD
import MNMDatabaseToolbox as DTB
import geopandas as GPD

suffix = "-testing"
# suffix = ""


base_folder = DTB.PL.Path(".")

loceval = DTB.ConnectDatabase(
    base_folder/"inbopostgis_server.conf",
    # connection_config = f"dumpall",
    # database = f"loceval{suffix}"
    connection_config = f"loceval{suffix}"
    )

mnmgwdb = DTB.ConnectDatabase(
    base_folder/"inbopostgis_server.conf",
    connection_config = f"mnmgwdb{suffix}",
    )
# mnmgwdb.config["database"]



### find local replacements

transfer_data = PD.read_sql_table( \
        "gwTransfer", \
        schema = "outbound", \
        con = loceval.connection \
    ).astype({"grts_address": int})
# transfer_data.loc[
#     NP.logical_and(
#         transfer_data["grts_address"].values == 23238,
#         transfer_data["eval_source"].values == "loceval"
#     ), :].T

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

# important: these are not relocated!



### relocate local replacements

# query = """
# SELECT
#   LOREP.wkb_geometry,
#   UNIT.type,
#   UNIT.grts_address,
#   UNIT.location_id,
#   LOREP.grts_address_replacement,
#   LOREP.replacement_rank,
#   LOREP.notes
# FROM "outbound"."SampleUnits" AS UNIT
# LEFT JOIN "outbound"."Replacements" AS LOREP
#   ON UNIT.sampleunit_id = LOREP.sampleunit_id
# WHERE UNIT.grts_address IN (
#   SELECT DISTINCT grts_address
#   FROM "outbound"."Replacements" AS RP
#   LEFT JOIN "outbound"."SampleUnits" AS SU
#   ON SU.sampleunit_id = RP.sampleunit_id
#   WHERE is_selected
#   AND NOT is_inappropriate
#   )
# ;
# """

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

new_locations = replacement_data.loc[
    [int(grts_repl) not in existing_locations["grts_address"].values \
     for grts_repl in replacement_data["grts_address_replacement"].values],
    :
]
# print("\n".join(map(str, list(map(int, sorted(existing_locations["grts_address"].values))))))

ogc_counter = int(existing_locations["ogc_fid"].max())
lid_counter = int(existing_locations["location_id"].max())

# insert new locations into locations; retrieve location_id
# idx = 0; row = new_locations.iloc[0, :]

clean_sqlstr = lambda txt: txt.replace("'", "")

# TODO this is a bit helpless; geopandas seems to fail uploading wkb :/
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




### intermediate cleaning up
# DELETE FROM "metadata"."Locations" WHERE location_id = 667;
# DELETE FROM "metadata"."Locations" WHERE location_id = 668;
# DELETE FROM "metadata"."Locations" WHERE location_id = 669;
# DELETE FROM "metadata"."Locations" WHERE location_id = 1352;


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

replacement_data

## also join samplelocation_id -> lookup to the SampleLocations

existing_samplelocations = PD.read_sql( \
    """SELECT DISTINCT grts_address, samplelocation_id
    FROM "outbound"."SampleLocations"
    ;
    """, \
    con = mnmgwdb.connection \
)
# NOTE: some locations have been mis-replaced previously; their original GRTS is not stored (yet)

replacement_data["samplelocation_id"] = NP.nan

missing = []
for idx, row in replacement_data.iterrows():
    # first, check the grts_address
    found_existing = \
        existing_samplelocations["grts_address"].values \
            == row["grts_address"]

    # if that is not found, check whether instead the location appears in previous replacements
    if not any(found_existing):
        found_existing = \
            existing_samplelocations["grts_address"].values \
                == row["grts_address_replacement"]

    # ... assemble the ones not found
    if not any(found_existing):
        print(idx, row)
        missing.append(idx)
    else:
        # finally, if it was found, just store the identifier
        replacement_data.loc[idx, "samplelocation_id"] = \
            existing_samplelocations.loc[found_existing, "samplelocation_id"].values[0]

## some of the sample location ids are recovered from the other replacements
missing_lookup = replacement_data.loc[:, ["grts_address", "samplelocation_id"]].dropna().drop_duplicates()
missing_lookup.set_index("grts_address", inplace = True)

for miss in missing:
    grts = replacement_data.loc[miss, "grts_address"]
    replacement_data.loc[miss, "samplelocation_id"] = \
        missing_lookup.loc[grts, "samplelocation_id"]

# (that data type issue again)
replacement_data["samplelocation_id"] = replacement_data["samplelocation_id"].astype(int)


print(replacement_data.sample(3).T)

### replace the location_id and grts in other tables
# TODO it is necessary to duplicate lines if strata of the same GRTS are moved to separate locations.
# TODO maybe retain original grts and stratum


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
    # identifier_old = 312
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
    index_newstring = ",".join( map(str, index_newvalues))

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
replacement_data["new_samplelocation_id"] = int(0)

for grts_to_replace in replacement_data["grts_address"].unique():
    this_grts_replacement = replacement_data.loc[
        replacement_data["grts_address"].values == grts_to_replace
        , :]

    if this_grts_replacement.shape[0] <= 1:
        continue

    # duplicate_index = 4
    # duplicate = this_grts_replacement.iloc[1, :]
    for duplicate_index, duplicate in this_grts_replacement.iloc[1:, :].iterrows():

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

        DuplicateTableRow(
            db = mnmgwdb,
            schema = "outbound",
            table_key = "SampleLocations",
            identifier_dict = {"samplelocation_id": old_samplelocation},
            index_columns = ["samplelocation_id"],
            index_newvalues = [samplelocation_next]
           )

        # important: store the right id
        replacement_data.loc[duplicate_index, "new_samplelocation_id"] = samplelocation_next


        ## duplicate FieldworkCalendar
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
            identifier_dict = {"samplelocation_id": old_samplelocation},
            index_columns = ["fieldworkcalendar_id", "samplelocation_id"],
            index_newvalues = [fwcal_next, samplelocation_next]
           )


        ## duplicate LocationEvaluations
        loceval_next = int(PD.read_sql(
            """
                SELECT locationevaluation_id FROM "outbound"."LocationEvaluations"
                ORDER BY locationevaluation_id DESC
                LIMIT 1;
            """,
            con = mnmgwdb.connection
           ).values[0, 0]) + 1

        # TODO !!!  this should rather be a re-link samplelocation_id based on grts and type
        print(duplicate)
        print(loceval_upload)
        grts_old = duplicate["grts_address"]
        grts_new = duplicate["grts_address_replacement"]
        type_new = duplicate["type"]

        # stratum_new = duplicate["stratum"]
        # TODO stratum by join

        update_command = f"""
                UPDATE "outbound"."LocationEvaluations"
                SET grts_address = {grts_new}, samplelocation_id = {samplelocation_next}
                WHERE grts_address = {grts_old} 
                  AND type = '{type_new}'
                  AND samplelocation_id = {old_samplelocation}
                ;
        """
        print(update_command)

        DTB.ExecuteSQL(mnmgwdb, update_command, verbose = True, test_dry = False)

        # DuplicateTableRow(
        #     db = mnmgwdb,
        #     schema = "outbound",
        #     table_key = "LocationEvaluations",
        #     identifier_dict = {"samplelocation_id": old_samplelocation},
        #     index_columns = ["locationevaluation_id", "type", "stratum"],
        #     index_newvalues = [loceval_next, type_new, type_new]
        #    )


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

        DuplicateTableRow(
            db = mnmgwdb,
            schema = "inbound",
            table_key = "Visits",
            identifier_dict = {"samplelocation_id": old_samplelocation},
            index_columns = ["fieldworkcalendar_id", "samplelocation_id", "visit_id"],
            index_newvalues = [fwcal_next, samplelocation_next, visit_next]
           )


        # TODO !!!! ALTER TABLE "outbound"."FieldworkCalendar" DROP CONSTRAINT "FieldworkCalendar_pkey" CASCADE;
        # TODO !!!! ALTER TABLE "inbound"."Visits" DROP CONSTRAINT "Visits_pkey" CASCADE;

        ## duplicate *Activities
        ## check if this is a WIA of CSA
        # activity_table  = "ChemicalSamplingActivities"
        for activity_table in ["WellInstallationActivities", "ChemicalSamplingActivities"]:
            check_query = f"""
            SELECT DISTINCT fieldwork_id FROM "inbound"."{activity_table}"
            WHERE samplelocation_id = {old_samplelocation};
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


#### updates of grts and location_id
## also update samplelocation_id

location_reference_list = {
    '"outbound"."SampleLocations"': {'grts': True, 'location_id': True, 'sloc': True},
    '"outbound"."FieldworkCalendar"': {'grts': True, 'location_id': False, 'sloc': True},
    '"inbound"."Visits"': {'grts': True, 'location_id': True, 'sloc': True},
    '"outbound"."LocationInfos"': {'grts': True, 'location_id': True, 'sloc': False},
    '"outbound"."LocationEvaluations"': {'grts': True, 'location_id': False, 'sloc': False}
}


# has_columns = {'grts': True, 'location_id': True}
# has_grts = has_columns['grts']
# has_location_id = has_columns['location_id']

# loop the tables to update
for table_namestring, has_columns in location_reference_list.items():
    has_grts = has_columns['grts']
    has_location_id = has_columns['location_id']
    has_sloc = has_columns['sloc']


    if has_sloc:
        for _, row in replacement_data.iterrows():
            # row = replacement_data.iloc[4, :]
            grts_old = val_to_int(row["grts_address"])
            grts_new = val_to_int(row["grts_address_replacement"])
            sloc_old = val_to_int(row["samplelocation_id"])
            sloc_new = val_to_int(row["new_samplelocation_id"])

            if (sloc_old == sloc_new) or (row["new_samplelocation_id"] == 0):
                continue

            update_command = f"""
                UPDATE {table_namestring}
                SET samplelocation_id = {sloc_new}
                WHERE grts_address = {grts_old} AND samplelocation_id = {sloc_old};
            """

            # print(update_command)
            DTB.ExecuteSQL(mnmgwdb, update_command, verbose = True, test_dry = False)

    # if the table has GRTS
    if has_grts:

        # loop all GRTS addresses

        for _, row in replacement_data.iterrows():
            grts_old = val_to_int(row["grts_address"])
            grts_new = val_to_int(row["grts_address_replacement"])
            sloc_new = val_to_int(row["new_samplelocation_id"])

            if grts_old == grts_new:
                continue

            if (not has_sloc) or (row["new_samplelocation_id"] == 0):
                filter_str = f"grts_address = {grts_old}"
            else:
                sloc_id = row["new_samplelocation_id"]
                filter_str = f"grts_address = {grts_old} AND samplelocation_id = {sloc_new}"

            update_command = f"""
                UPDATE {table_namestring}
                SET grts_address = {grts_new}
                WHERE {filter_str};
            """

            # print(update_command)
            DTB.ExecuteSQL(mnmgwdb, update_command, verbose = True, test_dry = False)


    if has_location_id:
        for _, row in replacement_data.iterrows():
            location_old = val_to_int(row["location_id"])
            location_new = val_to_int(row["new_location_id"])
            if location_old == location_new:
                continue

            if (not has_sloc) or (row["new_samplelocation_id"] == 0):
                filter_str = f"location_id = {location_old}"
            else:
                sloc_id = row["new_samplelocation_id"]
                filter_str = f"location_id = {location_old} AND samplelocation_id = {sloc_id}"


            update_command = f"""
                UPDATE {table_namestring}
                SET location_id = {location_new}
                WHERE {filter_str};
            """

            # print(update_command)

            DTB.ExecuteSQL(mnmgwdb, update_command, verbose = True, test_dry = False)


# SELECT * FROM "metadata"."Locations" WHERE grts_address = 23238 OR grts_address = 6314694;
# SELECT * FROM "outbound"."SampleLocations" WHERE is_replacement;
# SELECT * FROM "outbound"."SampleLocations" WHERE grts_address = 23238 OR grts_address = 6314694;
#
#
