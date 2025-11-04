alias:: MNMDatabaseConnection, DatabaseConnection
tags:: OOP

- R Script which **defines an object** to facilitate connection to the [[databases]].
- this is an attempt to improve usability of the database in [[usage/R]] by wrapping common methods into one object-like list
- see https://github.com/inbo/n2khab-mne-monitoring/blob/database_initialization/900_database_organization/MNMDatabaseConnection.R
- distinction: [[usage/R/MNMDatabaseToolbox]] is a collection of procedures that work on the connection object
- ## Conventions:
	- `table_namestring` is the SQL table reference including quotes,
	    e.g. `"metadata"."TeamMembers"`
	- `table_label` is just the case sensitive table name, e.g. `TeamMembers`
	- `table_key` is tha same as label, but can be all lowercase, e.g. `teammembers`
	- `table_id` is the DBI table identifier,
	    e.g. DBI::Id(schema = "metadata", table = "TeamMembers")
	- `db$` is the abstract variable name / `mnmdb$` is the same in applications
	   (analogous to class / object dualism)
	  
	  The `db$` (list) object brings functions and general structural information.
	  These functions are limited: they cannot change the `db$` object,
	  nor store data in R (though note that some functions do, of course, change
	  database content.
	  
	  ```
	  +---------------------------------------------------------------------+
	  | `db$` / `mnmdb$` bring database structure and references with them. |
	  +---------------------------------------------------------------------+
	  ```
	  no less, no more.
- # Methods
	- ## SQL Basics
		- > execute_sql(mnmdb, sql_command, verbose = TRUE) -> invisible(result)
		- > dump_all <- function(
		    config_filepath, database_to_dump, target_filepath,
		    connection_profile = "dumpall", exclude_schema = NULL) -> [file]
		- > append_tabledata <- function(
		    db_connection, table_id, data_to_append,
		    characteristic_columns = NA, verbose = TRUE ) -> [sql]
	- ## Database Structure
	  > read_table_relations_config(storage_filepath) -> relation_lookup
	- ## Connection Handling
		- > connect_database_configfile(
		    config_filepath, database, profile, host, port, user, password
		  ) -> database_connection
	- ## Database Workhorse
		- > connect_mnm_database(
		    config_filepath,
		    database_mirror = NA,
		    skip_structure_assembly = FALSE,
		    [... -> connection_database_configfile]
		  ) -> mnmdb
			- connection_profile
			- folder
			- host
			- port
			- database
			- user
			- shellstring
			- connection
			- execute_sql(self, ...) -> [reparametrization]
			- dump_all(self, ...) -> [reparametrization]
		- > mnmdb_assemble_structure_lookups(db) -> db
			- tables
			- has_table(table_label) -> bool
			- table_relations
			- excluded_tables
			- get_schema(table_label) -> character
			- get_namestring(table_label) -> character
			- get_table_id(table_label) -> DBI::Id
			- get_table_id_lowercase(table_key) -> DBI::Id
			- get_dependent_tables(table_key) -> c(key, df)
			- get_dependent_table_ids(table_key) -> list(DBI::Id)
			- load_table_info(table_label) -> df(table info)
			- get_characteristic_columns(table_label) -> c(column names)
			- get_primary_key(table_label) -> character(pk)
		- > mnmdb_assemble_query_functions(db) -> db
			- query_columns(table_label, select_columns) -> df(columns)
			- pull_column(table_label, select_column) -> c()
			- is_spatial(table_key) -> bool
			- query_table(table_label) -> df
			- query_tables_data(tables) -> list(df)
			- lookup_dependent_columns(table_label, deptab_label) -> df(pk, fk)
			- set_sequence_key(table_label, new_key_value, sequence_label, verbose)
			- insert_data(table_label, new_data)
			- store_table_deptree_in_memory(table_label) -> list("label", "data")
			- restore_table_data_from_memory(table_content_storage, verbose)
			- delete_unused(table_label, sql_filter_unused)
		- > mnmdb_versions_and_archiving(db) -> db
			- load_latest_version_id(version_tag, data_iteration) -> version_id
			- tag_new_version(version_tag, version_notes, date_applied) -> version_id