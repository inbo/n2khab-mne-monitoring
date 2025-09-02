
# Table of Contents

1.  [Purpose](#org1070e97)
2.  [Target Database](#org1e4fefd)
    1.  [create](#org788c4c9)
    2.  [extend](#org4e6d53c)
    3.  [automate](#org7778437)
3.  [Use Case 0: *tabula rasa*](#org28606e5)
    1.  [re-create empty](#org0146965)
    2.  [limitation](#orgf89d649)
4.  [Use Case 1: *tabula plena*](#org080f3ba)
    1.  [dump-reload](#org09d6982)
    2.  [limitation](#org015c406)
5.  [Use Case 2: *tabula semi-replenta*](#orgbb7b466)
    1.  [purpose](#org7355e35)
    2.  [source](#orgd97dc50)
    3.  [modify](#org53eeae5)
    4.  [target](#org3567f5e)
6.  [Generalization](#org4f16395)
7.  [Brief Data Inspection](#org8a6dccf)
8.  [Summary](#org47bd141)



<a id="org1070e97"></a>

# Purpose

Databases are astonishingly dynamic and volatile.
We would like to be able to move ours, in design and content, from one place to the other.

Here I document the required steps.

Terminology is quite straight-forward:

-   **source** is the database from which we migrate the data
-   **target**, on the otherhand, will mirror the source after this procedure

This document is an [orgmode](https://orgmode.org) document because, like the whole branch, it uses `sh`, `R`, and `Python`.
Orgmode allows me to &ldquo;tangle&rdquo; codeblocks to subsidiary files in the push of a button.


<a id="org1e4fefd"></a>

# Target Database


<a id="org788c4c9"></a>

## create

First of all, unless you have one already, it makes sense to create a new database.

The following steps are to be taken on the postgis server of choice.
Assuming you `ssh` into the server and switch to the `postgres` user.

    # switch to database maintainence
    su - postgres
    
    # drop-create
    # dropdb <database> -p <port>
    createdb <database> -O <owner> -p <port>


<a id="org4e6d53c"></a>

## extend

Next, we require the **postgis extension**:

    # switch to database maintainence
    su - postgres
    
    # either log in as maintainer:
    psql -p <port> -d <target database>
    
    # or use the database owner, via the whole connection specs:
    # psql -U <owner> -h <host-ip> -p <port> -d <target database> -W

    CREATE EXTENSION postgis;
    CREATE EXTENSION postgis_topology;
    CREATE EXTENSION fuzzystrmatch;
    CREATE EXTENSION postgis_tiger_geocoder;


<a id="org7778437"></a>

## automate

Some procedures, such as database backups, might need to be instantiated for the novel *target*.

For that purpose, occasional convenience is provided by [a `.pgpass` file](https://www.postgresql.org/docs/current/libpq-pgpass.html).

It can be appended by editing the `~/.pgpass`, appending a line for *target*:

    <target-host>:<port>:<target-database>:<read-only-user>:<password>

If the *target* is of permanent relevance, consider setting up a backup cronjob.
For now, that procedure remains documented in `000_steps_journal.org` >>> "`database daily diffs"`.


<a id="org28606e5"></a>

# Use Case 0: *tabula rasa*


<a id="org0146965"></a>

## re-create empty

Trivially, you can just create the new database as you created the original one.

    # DO NOT MODIFY
    # this file is "tangled" automatically from `030_copy_database.org`.
    
    import MNMDatabaseToolbox as DTB
    
    # database:
    base_folder = DTB.PL.Path(".")
    structure_folder = base_folder/"loceval_db_structure"
    DTB.ODStoCSVs(base_folder/"loceval_db_structure.ods", structure_folder)
    
    db_target = DTB.ConnectDatabase(
        "inbopostgis_server.conf",
        connection_config = "loceval-testing",
        database = "loceval_testing"
        )
    db = DTB.Database( \
        structure_folder = structure_folder, \
        definition_csv = "TABLES.csv", \
        lazy_creation = False, \
        db_connection = db_target, \
        tabula_rasa = False
        )


<a id="orgf89d649"></a>

## limitation

Obviously, this misses the point:
no database content is copied here, only the skeleton of the database is mirrored.

I can imagine certain situations in which you would like to restart empty.
And this might be a preliminary step for [the second use case, below](#orgbb7b466).


<a id="org080f3ba"></a>

# Use Case 1: *tabula plena*


<a id="org09d6982"></a>

## dump-reload

Now, it turns out that you can achieve the result we attempt below by a simple **dump-reload**.

    pg_dump -U <user1> -h <host1> -p <port1> -d <source> -W \
        > $(date +"%Y%m%d")_migration_dump.sql
    
    psql -U <user2> -h <host2> -p <port2> -d <source> -W \
        < $(date +"%Y%m%d")_migration_dump.sql


<a id="org015c406"></a>

## limitation

The dump-reload strategy might be a bit too drastic in certain situations, e.g.:

-   if there is already a structure and data on *target*
-   if you would like to slightly alter the *target* structure
-   if user/role permissions differ on the two databases


<a id="orgbb7b466"></a>

# Use Case 2: *tabula semi-replenta*


<a id="org7355e35"></a>

## purpose

This is the most surgical of the procedures.
Situation is that you have a *target* structure, possibly with valuable data,
but you would like to copy or append from a *source*.

Imagine you would like to copy over the `Protocols` table.

1.  Get the original data.
2.  (optional) Modify / adjust / update the data.
3.  Then, move it over.


<a id="orgd97dc50"></a>

## source

The source of your data can be any table which has approximately the same fields as the target database table.
You could use a `.csv` file, or another database.

Getting the data is as simple as establishing a connection and querying the table content.

    # DO NOT MODIFY
    # this file is "tangled" automatically from `030_copy_database.org`.
    
    source("MNMLibraryCollection.R")
    load_database_interaction_libraries()
    
    source("MNMDatabaseConnection.R")
    source("MNMDatabaseToolbox.R")
    # keyring::key_set("DBPassword", "db_user_password")
    
    migrating_table_label <- "Protocols"
    
    config_filepath <- file.path("./inbopostgis_server.conf")
    
    source_db <- connect_mnm_database(
      config_filepath,
      database_mirror = "loceval-dev"
    )
    
    source_data <- source_db$query_table(migrating_table_label)
    
    dplyr::glimpse(source_data)


<a id="org53eeae5"></a>

## modify

This is open to the concrete task.
Nevertheless, I find it useful to functionalize a bit, for reasons to be clarified below.

In the example case, we will just sort the protocols.

    #_______________________________________________________________________________
    ### ENTER YOUR CODE here to modify the data!
    
    sort_protocols <- function(prt) {
      prt <- prt %>% dplyr::arrange(dplyr::desc(protocol))
      return(prt)
    }
    source_data <- sort_protocols(source_data)
    
    source_data <- source_data %>%
      select(-protocol_id)
    #_______________________________________________________________________________


<a id="org3567f5e"></a>

## target

The third step was derived in detail in the `200_organized_backups.qmd` notebook,
and the `MNMDatabaseToolbox.R` contains a convenient function for it.

    
    upload_data_and_update_dependencies(
      source_db,
      table_label = migrating_table_label,
      data_replacement = source_data,
      verbose = FALSE
    )


<a id="org4f16395"></a>

# Generalization

Above is a simple example of table content moving from one to the other place.
Simple enough to be script-used heavily.

Make sure a read-only user is in `~/.pgpass`!

This requires minimal preparations, modification catalogue, and a loop.

    # DO NOT MODIFY
    # this file is "tangled" automatically from `030_copy_database.org`.
    
    source("MNMLibraryCollection.R")
    load_database_interaction_libraries()
    
    source("MNMDatabaseConnection.R")
    source("MNMDatabaseToolbox.R")
    # keyring::key_set("DBPassword", "db_user_password")
    
    # credentials are stored for easy access
    config_filepath <- file.path("./inbopostgis_server.conf")
    
    # database_label <- "mnmgwdb"
    database_label <- "loceval"
    source_mirror <- glue::glue("{database_label}")
    target_mirror <- glue::glue("{database_label}-dev")
    
    
    # from source...
    source_db <- connect_mnm_database(
      config_filepath,
      database_mirror = source_mirror,
      user = "monkey",
      password = NA
    )
    
    
    # ... to target
    target_db <- connect_mnm_database(
      config_filepath,
      database_mirror = target_mirror
    )

We certainly need to modify some tables.

    
    # TODO limitation: we should leave the primary and foreign keys unchanged!
    
    #_______________________________________________________________________________
    ### define functions here to modify the data!
    # modification is "on the go":
    #   each of these functions should receive exactly one data frame,
    #   just to give exactly one back.
    sort_protocols <- function(prt) {
      prt <- prt %>% dplyr::arrange(dplyr::desc(protocol))
      return(prt)
    }
    
    rename_FieldActivityCalendar <- function(fac) {
      fac <- fac %>% dplyr::rename(accessibility_revisit = acceccibility_revisit)
      return(fac)
    }
    
    #_______________________________________________________________________________
    ### associate the functions with table names
    
    table_modification <- c(
      "Protocols" = function (prt) sort_protocols(prt) # (almost) anything you like
      # "FieldActivityCalendar" = function (fac) rename_FieldActivityCalendar(fac) # (almost) anything you like
    )
    
    #_______________________________________________________________________________

> Nothing ever changes if noone uploads any data.

Here we go.

    
    copy_over_single_table <- function(table_label, new_data, ...) {
      # parametrization of the `upload_data_and_update_dependencies` functions
      # just to make the loop code below look a little less convoluted.
    
      # push the update
      upload_data_and_update_dependencies(
        target_db,
        table_label = table_label,
        data_replacement = new_data,
        verbose = FALSE,
        ...
      )
    
    }

Actually, what do we want to do to which tables?
Here we find out.

    
    table_list_file <- file.path(glue::glue("{source_db$folder}/TABLES.csv"))
    table_list <- read.csv(table_list_file)
    
    process_db_table_copy <- function(table_idx) {
    
      table_schema <- table_list[[table_idx, "schema"]]
      table_label <- table_list[[table_idx, "table"]]
      table_exclusion <- !is.na(table_list[[table_idx, "excluded"]]) && table_list[[table_idx, "excluded"]] == 1
    
      # print(table_list[[table_idx, "excluded"]])
    
      if (table_exclusion) return()
    
      print(glue::glue("processing {table_schema}.{table_label}"))
    
      # download
      source_data <- source_db$query_table(table_label)
    
      # modify
      if (table_label %in% names(table_modification)){
        source_data <- table_modification[[table_label]](source_data)
      }
    
      copy_over_single_table(table_label, source_data)
    
    }

Apply to all the table (never tired of reminding: **order matters**):

    
    # TODO due to ON DELETE SET NULL from "Locations", location_id's temporarily become NULL.
    #      Updating would be cumbersome.
    constraints_mod <- function(do = c("DROP", "SET")){
    
      toggle_null_constraint <- function(schema, table_label, column){
        # {dis/en}able fk for these tables
        target_db$execute_sql(
          glue::glue('ALTER TABLE "{schema}"."{table_label}" ALTER COLUMN {column} {do} NOT NULL;'),
          verbose = FALSE
        ) # /sql
      } # /toggle_mod
    
    
      if (database_label == "loceval") {
        # To prevent failure, I temporarily remove the constraint.
        for (table_label in c("LocationAssessments", "SampleUnits", "LocationInfos")){
          toggle_null_constraint("outbound", table_label, "location_id")
        } # /loop
    
        toggle_null_constraint("inbound", "Visits", "location_id")
        toggle_null_constraint("outbound", "ReplacementCells", "replacement_id")
      }
    
      if (database_label == "mnmgwdb") {
        # To prevent failure, I temporarily remove the constraint.
        for (table_label in c("SampleLocations", "LocationInfos")){
          toggle_null_constraint("outbound", table_label, "location_id")
        } # /loop
    
        toggle_null_constraint("inbound", "Visits", "location_id")
      }
    
    } #/constraints_mod
    
    #_______________________________________________________________________________
    # Finally, COPY ALL DATA
    
    constraints_mod("DROP")
    
    invisible(lapply(seq_len(nrow(table_list)), FUN = process_db_table_copy))
    
    constraints_mod("SET")

This is tested by comparing `pg_dump` of both databases after copying.

You might want to modify permissions for certain users on the target database.

    
    SET search_path TO public,"metadata","outbound","inbound","archive","analysis";
    
    GRANT USAGE ON SCHEMA "metadata" TO tester;
    GRANT SELECT ON ALL TABLES IN SCHEMA "metadata" TO tester;


<a id="org8a6dccf"></a>

# Brief Data Inspection

Some code snippets to check on relevant data (specific to `loceval`):

    SET search_path TO public,"metadata","outbound","inbound";
    SELECT DISTINCT assessment_done, COUNT(*) AS n FROM "outbound"."LocationAssessments" GROUP BY assessment_done;
    SELECT * FROM "inbound"."FreeFieldNotes";
    SELECT * FROM "inbound"."Visits" WHERE NOT (log_user = 'update');
    SELECT * FROM "inbound"."CellMaps";
    SELECT * FROM "archive"."ReplacementArchives";


<a id="org47bd141"></a>

# Summary

We now have a surgical method to transfer data from one to the other database.
Note the flexibility of the procedure above:

-   `table_modifications` can be applied on the way to match database structures in development
-   `update_datatable_and_dependent_keys` has some unused keywords which enable better data matching and column renaming.

One immediate purpose of these functions is to process updates of the POC.

