
# Table of Contents

1.  [Purpose](#orge221746)
2.  [Target Database](#org1954769)
    1.  [create](#org200efb8)
    2.  [extend](#org4d174f2)
    3.  [automate](#orgb7e2018)
3.  [Use Case 0: *tabula rasa*](#org9355ced)
    1.  [re-create empty](#org73b6283)
    2.  [limitation](#orgaa7a1ac)
4.  [Use Case 1: *tabula plena*](#orga4a709f)
    1.  [dump-reload](#orgc6737a0)
    2.  [limitation](#orgeaa3f83)
5.  [Use Case 2: *tabula semi-replenta*](#org30b569d)
    1.  [purpose](#org459f98c)
    2.  [source](#org486672a)
    3.  [modify](#orge4794c9)
    4.  [target](#orga1d5744)
6.  [Generalization](#org773857b)
7.  [Summary](#orge5a661a)



<a id="orge221746"></a>

# Purpose

Databases are astonishingly dynamic and volatile.
We would like to be able to move ours, in design and content, from one place to the other.

Here I document the required steps.

Terminology is quite straight-forward:

-   **source** is the database from which we migrate the data
-   **target**, on the otherhand, will mirror the source after this procedure

This document is an [orgmode](https://orgmode.org) document because, like the whole branch, it uses `sh`, `R`, and `Python`.
Orgmode allows me to &ldquo;tangle&rdquo; codeblocks to subsidiary files in the push of a button.


<a id="org1954769"></a>

# Target Database


<a id="org200efb8"></a>

## create

First of all, unless you have one already, it makes sense to create a new database.

The following steps are to be taken on the postgis server of choice.
Assuming you `ssh` into the server and switch to the `postgres` user.

    # switch to database maintainence
    su - postgres
    
    # drop-create
    # dropdb <database> -p <port>
    createdb <database> -O <owner> -p <port>


<a id="org4d174f2"></a>

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


<a id="orgb7e2018"></a>

## automate

Some procedures, such as database backups, might need to be instantiated for the novel *target*.

For that purpose, occasional convenience is provided by [a `.pgpass` file](https://www.postgresql.org/docs/current/libpq-pgpass.html).

It can be appended by editing the `~/.pgpass`, appending a line for *target*:

    <target-host>:<port>:<target-database>:<read-only-user>:<password>

If the *target* is of permanent relevance, consider setting up a backup cronjob.
For now, that procedure remains documented in `000_steps_journal.org` >>> "`database daily diffs"`.


<a id="org9355ced"></a>

# Use Case 0: *tabula rasa*


<a id="org73b6283"></a>

## re-create empty

Trivially, you can just create the new database as you created the original one.

    import MNMDatabaseToolbox as DTB
    
    # database:
    base_folder = DTB.PL.Path(".")
    structure_folder = base_folder/"devdb_structure"
    DTB.ODStoCSVs(base_folder/"loceval_dbstructure.ods", structure_folder)
    
    db_target = DTB.ConnectDatabase(
        "inbopostgis_server.conf",
        connection_config = "testing",
        database = "loceval_testing"
        )
    db = DTB.Database( \
        structure_folder = structure_folder, \
        definition_csv = "TABLES.csv", \
        lazy_creation = False, \
        db_connection = db_target, \
        tabula_rasa = False
        )


<a id="orgaa7a1ac"></a>

## limitation

Obviously, this misses the point:
no database content is copied here, only the skeleton of the database is mirrored.

I can imagine certain situations in which you would like to restart empty.
And this might be a preliminary step for [the second use case, below](#org30b569d).


<a id="orga4a709f"></a>

# Use Case 1: *tabula plena*


<a id="orgc6737a0"></a>

## dump-reload

Now, it turns out that you can achieve the result we attempt below by a simple **dump-reload**.

    pg_dump -U <user1> -h <host1> -p <port1> -d <source> -W \
        > $(date +"%Y%m%d")_migration_dump.sql
    
    psql -U <user2> -h <host2> -p <port2> -d <source> -W \
        < $(date +"%Y%m%d")_migration_dump.sql


<a id="orgeaa3f83"></a>

## limitation

The dump-reload strategy might be a bit too drastic in certain situations, e.g.:

-   if there is already a structure and data on *target*
-   if you would like to slightly alter the *target* structure
-   if user/role permissions differ on the two databases


<a id="org30b569d"></a>

# Use Case 2: *tabula semi-replenta*


<a id="org459f98c"></a>

## purpose

This is the most surgical of the procedures.
Situation is that you have a *target* structure, possibly with valuable data,
but you would like to copy or append from a *source*.

Imagine you would like to copy over the `Protocols` table.

1.  Get the original data.
2.  (optional) Modify / adjust / update the data.
3.  Then, move it over.


<a id="org486672a"></a>

## source

The source of your data can be any table which has approximately the same fields as the target database table.
You could use a `.csv` file, or another database.

Getting the data is as simple as establishing a connection and querying the table content.

    library("dplyr")
    source("MNMDatabaseToolbox.R")
    # keyring::key_set("DBPassword", "db_user_password")
    
    migrating_table_key <- "Protocols"
    migrating_table <- DBI::Id(schema = "metadata", table = migrating_table_key)
    
    source_db_connection <- connect_database_configfile(
      config_filepath = file.path("./inbopostgis_server.conf"),
      profile = "inbopostgis-dev",
      database = "loceval_dev"
    )
    
    protocols_data <- dplyr::tbl(
        source_db_connection,
        migrating_table
      ) %>%
      collect() # collecting is necessary to modify offline and to re-upload
    
    dplyr::glimpse(protocols_data)


<a id="orge4794c9"></a>

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
    protocols_data <- sort_protocols(protocols_data)
    
    protocols_data <- protocols_data %>%
      select(-protocol_id)
    #_______________________________________________________________________________


<a id="orga1d5744"></a>

## target

The third step was derived in detail in the `200_organized_backups.qmd` notebook,
and the `MNMDatabaseToolbox.R` contains a convenient function for it.

    
    update_datatable_and_dependent_keys(
      config_filepath = file.path("./inbopostgis_server.conf"),
      working_dbname = "loceval_testing",
      table_key = migrating_table_key,
      new_data = protocols_data,
      profile = "testing",
      dbstructure_folder = "devdb_structure",
      verbose = FALSE
    )


<a id="org773857b"></a>

# Generalization

Above is a simple example of table content moving from one to the other place.
Simple enough to be script-used heavily.

This requires minimal preparations, modification catalogue, and a loop.

    library("dplyr")
    source("MNMDatabaseToolbox.R")
    # keyring::key_set("DBPassword", "db_user_password")
    
    # credentials are stored for easy access
    config_filepath = file.path("./inbopostgis_server.conf")
    dbstructure_folder = "devdb_structure"
    
    # from source...
    source_db_connection <- connect_database_configfile(
      config_filepath = config_filepath,
      profile = "inbopostgis-dev",
      database = "loceval_dev"
    )
    
    # ... to target
    target_db_name <- "loceval_testing"
    target_connection_profile <- "testing"
    target_db_connection <- connect_database_configfile(
      config_filepath = config_filepath,
      profile = target_connection_profile,
      database = target_db_name
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
    
    
    #_______________________________________________________________________________
    ### associate the functions with table names
    
    table_modification <- c(
      "Protocols" = function (prt) sort_protocols(prt) # (almost) anything you like
    )
    
    #_______________________________________________________________________________

> Nothing ever changes if noone uploads any data.

Here we go.

    
    copy_over_single_table <- function(table_key, new_data) {
      # just to make the loop code below look a little less convoluted.
    
      # push the update
      update_datatable_and_dependent_keys(
        config_filepath = config_filepath,
        working_dbname = target_db_name,
        table_key = table_key,
        new_data = new_data,
        profile = target_connection_profile,
        dbstructure_folder = dbstructure_folder,
        db_connection = target_db_connection,
        verbose = FALSE
      )
    
    }

Actually, what do we want to do to which tables?
Here we find out.

    
    table_list_file <- file.path(glue::glue("{dbstructure_folder}/TABLES.csv"))
    table_list <- read.csv(table_list_file)
    
    process_db_table_copy <- function(table_idx){
    
      table_schema <- table_list[[table_idx, "schema"]]
      table_key <- table_list[[table_idx, "table"]]
      table_exclusion <- !is.na(table_list[[table_idx, "excluded"]]) && table_list[[table_idx, "excluded"]] == 1
    
      print(table_list[[table_idx, "excluded"]])
    
      if (table_exclusion) return()
    
      print(glue::glue("processing {table_schema}.{table_key}"))
    
      # download
      source_data <- dplyr::tbl(
          source_db_connection,
          DBI::Id(schema = table_schema, table = table_key)
        ) %>%
        collect() # collecting is necessary to modify offline and to re-upload
    
      # modify
      if (table_key %in% names(table_modification)){
        source_data <- table_modification[[table_key]](source_data)
      }
    
      copy_over_single_table(table_key, source_data)
    
    }

Apply to all the table (never tired of reminding: **order matters**):

    
    # TODO due to ON DELETE SET NULL from "Locations", location_id's temporarily become NULL.
    constraints_mod <- function(do = c("DROP", "SET")){
      # To prevent failure, I temporarily remove the constraint.
      for (table_key in c("LocationAssessments", "SampleLocations")){
    
        execute_sql(
          target_db_connection,
          glue::glue('ALTER TABLE "outbound"."{table_key}" ALTER COLUMN location_id {do} NOT NULL;')
        )
      }
    }
    
    
    constraints_mod("DROP")
    
    invisible(lapply(1:nrow(table_list), FUN = process_db_table_copy))
    
    constraints_mod("SET")

This is tested by comparing `pg_dump` of both databases after copying.


<a id="orge5a661a"></a>

# Summary

We now have a surgical method to transfer data from one to the other database.
Note the flexibility of the procedure above:

-   `table_modifications` can be applied on the way to match database structures in development
-   `update_datatable_and_dependent_keys` has some unused keywords which enable better data matching and column renaming.

One immediate purpose of these functions is to process updates of the POC.

