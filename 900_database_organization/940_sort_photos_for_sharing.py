#!/usr/bin/env python3

# This script will connect the database,
# gather information about photos,
# link associated information with the photo file (WATINA code, teammember, date)
# and copy the photos to a new folder structure.

import pathlib as PL
import shutil as SHU
import numpy as NP
import pandas as PD
import MNMDatabaseToolbox as DTB




if __name__ == "__main__":


    locevaldb = DTB.ConnectDatabase(
        "mnm_database_connection.conf",
        connection_config = "loceval",
        database = "loceval",
        user = "monkey",
        password = None
        )

    mnmgwdb = DTB.ConnectDatabase(
        "mnm_database_connection.conf",
        connection_config = "mnmgwdb",
        database = "mnmgwdb",
        user = "monkey",
        password = None
        )

    # query team members
    team = DTB.QueryTable(
        mnmgwdb,
        ["metadata", "TeamMembers"],
        columns = ["teammember_id", "given_name", "family_name"]
    ).dropna(inplace = False)

    team.set_index("teammember_id", inplace = True)
    team.loc[0, :] = ["unknown", ""]


    # query team members
    team_l = DTB.QueryTable(
        locevaldb,
        ["metadata", "TeamMembers"],
        columns = ["teammember_id", "given_name", "family_name"]
    ).dropna(inplace = False)

    team_l.set_index("teammember_id", inplace = True)
    team_l.loc[0, :] = ["unknown", ""]


    # print(team)


    # installation photos
    fixed_columns = ["grts_address", "log_user", "visit_done"]
    invi_cols = fixed_columns + [
        "teammember_id",
        # "photo",
        "date_visit",
        "watina_code_used_1_peilbuis",
        "watina_code_used_2_piezometer",
        "photo_soil_1_peilbuis",
        "photo_soil_2_piezometer",
        "photo_well",
    ]

    invi = DTB.QueryTable(
        mnmgwdb,
        ["inbound", "InstallationVisits"],
        columns = invi_cols
    ).dropna(
        how = "all",
        subset = [col for col in invi_cols if not col in fixed_columns],
        inplace = False
    )

    missing_teammember = invi.loc[PD.isna(invi["teammember_id"].values), :]
    print(missing_teammember)
    invi.loc[PD.isna(invi["teammember_id"].values), "teammember_id"] = 0

    invi["teammember_id"] = invi["teammember_id"].astype(int)
    invi = invi.join(team, how = "left", on = "teammember_id")

    print(invi.sample(1).T)

    # watina code lookup
    watinacode_lookup = invi \
        .loc[:, ["grts_address", "watina_code_used_1_peilbuis", "watina_code_used_2_piezometer"]] \
        .drop_duplicates(inplace = False) \
        .set_index("grts_address") \
        .rename(columns = {"watina_code_used_1_peilbuis": "wc1", "watina_code_used_2_piezometer": "wc2"})

    wc2_nas = PD.isna(watinacode_lookup["wc2"].values)
    watinacode_lookup.loc[wc2_nas, "wc2"] = watinacode_lookup.loc[wc2_nas, "wc1"].values
    watinacode_lookup = watinacode_lookup.loc[:, ["wc2"]].dropna(inplace = False)

    print(watinacode_lookup.sample(5))


    # all gwdb visits
    visit_cols = fixed_columns + [
        "teammember_id",
        "photo",
        "date_visit"
    ]

    visits = DTB.QueryTable(
        mnmgwdb,
        ["inbound", "Visits"],
        columns = visit_cols
    ).dropna(
        how = "all",
        subset = [col for col in visit_cols if not col in fixed_columns],
        inplace = False
    ).dropna(subset = ["photo"], inplace = False) \
    .join(watinacode_lookup, on = "grts_address", how = "left") \
    .dropna(subset = ["wc2"], inplace = False)

    missing_colleagues = PD.isna(visits["teammember_id"].values)
    visits.loc[missing_colleagues, "teammember_id"] = 0
    print(visits.loc[missing_colleagues, :])


    visits["teammember_id"] = visits["teammember_id"].astype(int)
    visits = visits.join(team, how = "left", on = "teammember_id")

    print(visits.sample(1).T)

    # loceval visits
    loceval_cols = fixed_columns + [
        "teammember_id",
        "photo",
        "date_visit"
    ]

    locevals = DTB.QueryTable(
        locevaldb,
        ["inbound", "Visits"],
        columns = visit_cols
    ).dropna(
        how = "all",
        subset = [col for col in visit_cols if not col in fixed_columns],
        inplace = False
    ).dropna(subset = ["photo"], inplace = False) \
    .join(watinacode_lookup, on = "grts_address", how = "left") \
    .dropna(subset = ["wc2"], inplace = False)

    missing_colleagues = PD.isna(locevals["teammember_id"].values)
    locevals.loc[missing_colleagues, "teammember_id"] = 0
    print(locevals.loc[missing_colleagues, :])


    locevals["teammember_id"] = locevals["teammember_id"].astype(int)
    locevals = locevals.join(team_l, how = "left", on = "teammember_id")

    print(locevals.sample(1).T)


    ## concatenate all possible photos
    loceval_photos = locevals.loc[:, ["given_name", "family_name", "date_visit", "wc2", "photo"]] \
        .rename(columns = {"wc2": "watina_code"})
    loceval_photos.loc[:, "occasion"] = "loceval"

    visit_photos = visits.loc[:, ["given_name", "family_name", "date_visit", "wc2", "photo"]] \
        .rename(columns = {"wc2": "watina_code"})
    visit_photos.loc[:, "occasion"] = "visit"

    pbpm = "2_piezometer"
    install_photos_1 = invi.loc[:, ["given_name", "family_name", "date_visit", f"watina_code_used_{pbpm}", "photo_well"]] \
        .rename(columns = {f"watina_code_used_{pbpm}": "watina_code", "photo_well": "photo"})
    install_photos_1.loc[:, "occasion"] = "install_piezometer"

    soilp_photos_1 = invi.loc[:, ["given_name", "family_name", "date_visit", f"watina_code_used_{pbpm}", f"photo_soil_{pbpm}"]] \
        .rename(columns = {f"watina_code_used_{pbpm}": "watina_code", f"photo_soil_{pbpm}": "photo"})
    soilp_photos_1.loc[:, "occasion"] = "bodemp_piezometer"

    pbpm = "1_peilbuis"
    install_photos_2 = invi.loc[:, ["given_name", "family_name", "date_visit", f"watina_code_used_{pbpm}", "photo_well"]] \
        .rename(columns = {f"watina_code_used_{pbpm}": "watina_code", "photo_well": "photo"})
    install_photos_2.loc[:, "occasion"] = "install_peilbuis"


    soilp_photos_2 = invi.loc[:, ["given_name", "family_name", "date_visit", f"watina_code_used_{pbpm}", f"photo_soil_{pbpm}"]] \
        .rename(columns = {f"watina_code_used_{pbpm}": "watina_code", f"photo_soil_{pbpm}": "photo"})
    soilp_photos_2.loc[:, "occasion"] = "bodemp_peilbuis"


    all_photos = PD.concat([
        loceval_photos,
        visit_photos,
        install_photos_1,
        install_photos_2,
        soilp_photos_1,
        soilp_photos_2
    ]).dropna()

    all_photos['date_visit'] = all_photos['date_visit'].dt.strftime('%Y-%m-%d')
    all_photos['region'] = all_photos['watina_code'].str.slice(0, 3)
    all_photos['extension'] = [
        PL.Path(fi).suffix
        for fi in all_photos['photo'].values
    ]

    all_photos.sort_values("date_visit", inplace = True)
    all_photos.reset_index(inplace = True)

    print(all_photos.sample(10))
    all_photos.to_csv(PL.Path("data")/"photos_all.csv")


    ### Distribute Files
    # folder structure: MNM/[region]/{watina_code}_{date_visit}_{given_name}_{occasion}.{ext}

    path_in = PL.Path(".") / "photos"
    path_out = PL.Path(".") / "Foto-archief MNM"
    missing_files = {}
    for idx, photo in all_photos.iterrows():
        region = photo["region"]

        fi_path = path_out / region
        if not fi_path.is_dir():
            fi_path.mkdir()

        fi_in = path_in / photo["photo"]
        fi_out = fi_path / "{watina_code}_{date_visit}_{given_name}_{occasion}{extension}".format(**photo.to_dict())

        if not fi_in.exists():
            missing_files[idx] = photo
            continue

        if not fi_out.exists():
            print(fi_in, " -> ", fi_out)
            SHU.copy(fi_in, fi_out)


    # store missing photos
    missing = PD.DataFrame.from_dict(missing_files).T
    missing.to_csv(PL.Path("data")/"photos_missing.csv")

    print("done!")


    # example: loceval_20260713162820191
