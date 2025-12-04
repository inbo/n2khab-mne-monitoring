#!/usr/bin/env python3

import sys as SYS
import os as OS
import time as TI
import atexit as EXIT
import warnings as WRN
import pathlib as PL
import getpass as PWD
import sqlalchemy as SQL
import pandas as PD
import geopandas as GPD
import configparser as CONF


def WriteExampleConfig(config_filename = "postgis_server.conf", server_label = "default"):
    # this will create an example config file; with the following content.
    # WARNING: passwords are stored in plain text.
    """
    [profile-name]
    host = localhost
    port = 5439
    user = test
    database = playground
    password = <the password you entered IN PLAIN TEXT>
    """

    config = CONF.ConfigParser()
    config[server_label] = {
        'host': 'localhost',
        'port': '5439',
        'user': 'test'
        # 'database': 'playground'
    }
    # we usually give the database via ConnectDatabase(), but you could as well store it.

    config[server_label]['password'] = PWD.getpass("password: ")

    with open(config_filename, 'w') as configfile:
      config.write(configfile)


def ODStoCSVs(infile, outfolder):
    # convert all sheets of an `.ods` LibreOffice spreadsheet
    # to `.csv` files in a target directory

    data = PD.read_excel(infile, sheet_name = None,
                         na_values=[], keep_default_na=False)

    for sheetname, table in data.items():

        for bool_column in ["not_null", "primary_key", "sequence"]:
            if bool_column in table.columns:
                table[bool_column] = table[bool_column].astype(bool)
        table.to_csv(outfolder/f"{sheetname}.csv", index = False)


def ReadSQLServerConfig(config_filename = "postgis_server.conf", profile = None, **kwargs):
    # will read sql configuration from a text file.

    # parse the config with the config parser
    config = CONF.ConfigParser()
    config.read(config_filename)

    # per default, take first section
    if profile is None:
        server_label = config.sections()[0]
    else:
        server_label = profile

    # convert to dictionary
    db_configuration = dict(config[profile])

    # extra arguments
    for kw, val in kwargs.items():
        db_configuration[kw] = val

    if db_configuration["database"] is None:
        for k, v in db_configuration.items():
            if k not in ["password"]:
              print(k, v)

        raise Exception("Please provide a database for SQL connection!"
        + " (None found in the config file, none provided in keyword args.)")


    # prompt password
    if 'password' not in db_configuration.keys():
        db_configuration['password'] = PWD.getpass(f"password {db_configuration['user']}: ")

    return(db_configuration)


def ConfigToConnectionString(config: dict) -> str:
    # concatenate the connection string from a config dict
    # TODO: prompt user to enter missing connection info; store in config

    defaults = {"port": 5439, "host": "localhost"}
    config_relevant = {k: config.get(k, defaults.get(k, None))
                       for k in ["host", "port", "user", "database", "password"]}

    if type(config_relevant["port"]) is not str:
        # ensure port numeric to string
        config_relevant["port"] = f"{config_relevant["port"]:%.0f}"

    conn_str = """postgresql://{user}:{password}@{host}:{port}/{database}""".format(
        **config_relevant
    )

    return(conn_str)


class DatabaseConnection(object):
    # a database connection;
    # basically an SQLAlchemy connection pass-through, but with some extra spice.

    def __init__(self, config):

        self.config = config
        self.engine = SQL.create_engine(ConfigToConnectionString(config))
        self.connection = self.engine.connect()

        # print(self.connection)
        EXIT.register(self.connection.close)

        # register some pass-through functions
        self.execute = self.connection.execute
        self.commit = self.connection.commit
        self.close = self.connection.close
        self.info = self.connection.info
        # print(dir(self.connection))

    def __str__(self):
        return(str({k: v for k, v in self.config.items() if not k == "password"}))

    def HasTable(self, table, schema = 'public'):
        # check if a table is present in the data
        return(SQL.inspect(self.engine).has_table(table, schema = schema))

    def DumpAll( \
            self, \
            target_filepath: PL.Path, \
            exclude_schema: list = ["tiger", "public"], \
            **kwargs \
        ) -> None:
        # pg_dump a given database
        # make sure that the user is in the `~/.pgpass` file
        # config is used, but kwargs can overwrite connection parameters

        if exclude_schema is None:
            exclude_schema = ""
        else:
            exclude_schema = " ".join([f"-N {schema}" for schema in exclude_schema])

        dumplings = {} # dump connection parameters
        for param in ["user", "host", "database", "port"]:
            # if provided, use function kwargs; otherwise default to config
            dumplings[param] = kwargs.get(param, self.config[param])

        # create the dump command
        dump_command = f"""
            pg_dump -U {dumplings["user"]} -h {dumplings["host"]} -p {dumplings["port"]} -d {dumplings["database"]} {exclude_schema} --no-password > {target_filepath}
        """

        # perform the dump
        OS.system(dump_command)


def ConnectDatabase(config_filepath, database = None, connection_config = None, **kwargs):
    # https://stackoverflow.com/a/42772654
    # user = input("user: ")

    if database is None:
        config = ReadSQLServerConfig(config_filepath, profile = connection_config, **kwargs)
    else:
        config = ReadSQLServerConfig(config_filepath, profile = connection_config, database = database, **kwargs)

    connection = DatabaseConnection(config)

    return(connection)


def ExecuteSQL(db_connection, sql_command, verbose = True, test_dry = False) -> None:
    # execute an sql statement, with all the necessary connection management

    if verbose:
        print(sql_command)

    if test_dry:
        print("skipped.")
        return

    db_connection.execute(SQL.text(sql_command))
    db_connection.commit()

    if verbose:
        print("done.")


def CreateSchema(db_connection, definition_csv: str, selection: set = None, drop: bool = True, verbose: bool = True, dry: bool = False):
    # initialize a database scheme

    # read the schema definition table
    schema_definitions = PD.read_csv(definition_csv).set_index("schema", inplace = False)

    # optionally select a subset of the defined schemas
    if selection is None:
        selection = schema_definitions.index.values

    if verbose:
        print("#"*32)
        print("Creating schema's", selection)

    # concatenate a creation string
    create_string = ""
    for schema in selection:

        # we need to set the owner and users with read-access.
        owner = schema_definitions.loc[schema, "owner"]
        usage = schema_definitions.loc[schema, "usage"].split(",")

        # dropping previous installments of the schema is optional
        if drop:
            create_string += f"""
                DROP SCHEMA IF EXISTS "{schema}" CASCADE;
            """

        # main creation string
        create_string += f"""
            CREATE SCHEMA "{schema}";
            ALTER SCHEMA "{schema}" OWNER TO {owner};
        """

        # ... and the users
        for user in usage:
            create_string += f"""
                GRANT USAGE ON SCHEMA "{schema}" TO {user};
            """

    # append the search string
    # to make the content of the schema available for access
    all_schemas = ",".join(["pg_catalog", "public"] + [f'"{schema}"' for schema in selection])
    create_string += f"""
        SET search_path TO {all_schemas};
    """

    # better format
    create_string = create_string.replace("    ", "")

    # Finally, run the SQL
    if not dry:
        ExecuteSQL(db_connection, create_string, verbose = verbose)
    elif verbose:
        # ... or just print, in case of a dry run.
        print(create_string)


def GetGeometryString(schema, table, geometry_type, crs = "31370", dims = '2'):
    # retrieve the geometry column creation string

    if geometry_type not in [
        "POINT", "MULTIPOINT",
        "LINESTRING", "MULTILINESTRING",
        "POLYGON", "MULTIPOLYGON",
        ]:
        # only these types are tested and used.
        return("")

    geometry_strings = f"""
        ALTER TABLE "{schema}"."{table}" ADD COLUMN "ogc_fid" SERIAL CONSTRAINT "pk_{table.lower()}_fid" PRIMARY KEY;
        SELECT AddGeometryColumn('{schema}', '{table}', 'wkb_geometry', {crs}, '{geometry_type}', {dims});
        CREATE INDEX "{table.lower()}_wkb_geometry_geom_idx" ON "{schema}"."{table}" USING GIST ("wkb_geometry");
    """

    return(geometry_strings)


def ColumnString(schema, table, fieldname, params, no_pk = False):
    # concatenate field creation string

    # the basis: ADD COLUMN
    field_creation = f"""ALTER TABLE "{schema}"."{table}" ADD COLUMN """

    # prepare all optional attributes
    attributes = [
        fieldname,
        params["datatype"]
    ]
    if params["not_null"]:
        attributes += ["NOT NULL"]

    # default
    if params["default"] == "NULL":
        attributes += ["DEFAULT NULL"]
    elif not PD.isna(params["default"]):
        value = params["default"]
        # print(fieldname, value, str(bool(value)).upper())
        if (params["datatype"].lower() == "boolean") \
         or (params["datatype"].lower() == "bool"):
            value = str(bool(int(value))).upper()

        attributes += [f"""DEFAULT {str(value)}"""]

    # pk

    # print (schema, table, "pk", not no_pk, params["primary_key"],
    #        params["constraint"], ("UNIQUE" not in str(params["constraint"]).upper()))
    if (not no_pk) and (params["primary_key"] is True):
        attributes += [f"""PRIMARY KEY"""]

    # constraints
    if not PD.isna(params["constraint"]):
        attributes += [params["constraint"]]
    if (no_pk) and (params["primary_key"] is True):
        attributes += ["UNIQUE"]


    # free sql to add
    if not PD.isna(params["freesql"]):
        attributes += [params["freesql"]]

    # print(attributes)

    # join field creation/attributes
    field_creation += " ".join(attributes)

    # add comment
    comment = params["comment"]
    field_creation = f"""\n    {field_creation}; """ + \
        f"""
            COMMENT ON COLUMN "{schema}"."{table}".{fieldname} IS E'{comment}';
        """

    # return the combined string
    return(field_creation)


def SequenceString(schema, table, sequence_column, owner):
    # parametrized SQL string to insert a SEQUENCE

    return(f"""
                -- sequence {sequence_column}
                CREATE SEQUENCE "{schema}".seq_{sequence_column}
                    INCREMENT BY 1
                    MINVALUE 0
                    MAXVALUE 2147483647
                    START WITH 1
                    CACHE 1
                    NO CYCLE
                    OWNED BY "{schema}"."{table}".{sequence_column};
                ALTER TABLE "{schema}"."{table}" ALTER COLUMN {sequence_column}
                 SET DEFAULT nextval('{schema}.seq_{sequence_column}'::regclass);
            """)

                # ALTER SEQUENCE "{schema}".seq_{sequence_column} OWNER TO {owner};

def ForeignKeyString(schema, table, col, refcol):
    # parametrized SQL string to link a foreign key

    fk = refcol.split(".")
    label = f"fk_{fk[-2]}_{table}"
    if len(fk) > 2:
        target_schema = fk[0]
    else:
        target_schema = schema
    fokey_string = f"""
        -- foreign key {col}
        ALTER TABLE "{schema}"."{table}" DROP CONSTRAINT IF EXISTS {label} CASCADE;
        ALTER TABLE "{schema}"."{table}" ADD CONSTRAINT {label} FOREIGN KEY ({col})
            REFERENCES "{target_schema}"."{fk[-2]}" ({fk[-1]}) MATCH SIMPLE
            ON DELETE SET NULL ON UPDATE CASCADE;
    """
    # note the last line: we can delete, and cascade updates
    return(fokey_string)


def GrantPermissionString(schema, table, user, role):
    # parametrized sql string to grant some permission (role) to a user.
    return(f"""
        GRANT {role} ON "{schema}"."{table}" TO {user};
    """)


def EnsureNestedQuerySpacing(query: str) -> str:
    # make sure that SQL keywords stand separated
    # (solve problem arising from cell linebreaks)

    # some sql keywords get crunched by gsheet cell walls
    for keyword in [ \
              "SELECT", "FROM", "WHERE" \
            , "UPDATE", "ON UPDATE", "INSTEAD" \
            , " ON ", " AS " # note that "AS" without space is in "CASE", and "ON" is in "FUNCTION" \
            , "AND NOT", " AND " \
            , "LEFT JOIN", "UNION" \
            , "DISTINCT", "GROUP BY", "ORDER BY" \
            , "CASE WHEN", "THEN", "ELSE", "END" \
            , "BEFORE", "BEGIN", "END" \
            , "CREATE", "DROP", "FOR EACH", "EXECUTE" \
            , "MATCH", "SIMPLE", "ON DELETE", "ON UPDATE", "CASCADE" \
            , "INCREMENT", "MINVALUE", "MAXVALUE", "START WITH", "CACHE", "NO CYCLE" \
        ]:
        query = query.replace(keyword, f"\n\t{keyword} ")

    # there also was a stupid rare mistake in update rules
    for typo, replacement in {
        "ASON": "AS ON"
        }.items():
        query = query.replace(typo, replacement)

    # print(query.replace("    ", ""))
    return query.replace("    ", "")



class dbTable(dict):
    # a class to store all required attributes and functionality
    # to handle a table in the database.

    def __init__(self, tabledef: dict, structure_folder: PL.Path = PL.Path("./db_structure")):
        # | self.schema       | self.table        | self.owner       |
        # | self.read_access  | self.write_access | self.geometry    |
        # | self.constraint   | self.freesql      | self.persistent  |
        # | self.comment      | self.excluded     |                  |

        self.structure_folder = structure_folder

        for k, v in tabledef.items():
            setattr(self, k, v)

        self.definition_file = self.structure_folder/f"{self.table}.csv"

        table_definitions = PD.read_csv(self.definition_file)
        for _, datafield in table_definitions.iterrows():
            nm = datafield["column"]
            self[nm] = datafield.to_dict()

        # initialize empty
        self.data = None

    def NameString(self):
        return(f""" "{self.schema}"."{self.table}" """.strip())

    def GetPrimaryKey(self):
        # retrieve primary key column

        pk_fields = [field for field, definition in self.items() \
            if definition["primary_key"]]

        return(pk_fields)


    def ListDependencies(self):
        # find other tables on which this one depends

        fk_fields = [(
            field,
            "metadata.Locations.location_id" if (field == "location_id")
                else definition["foreign_key"]
            ) \
            for field, definition in self.items() \
            if (not PD.isna(definition["foreign_key"])) \
              or (field == "location_id") \
              and not (field in self.GetPrimaryKey()) \
            ]

        # print(fk_fields)

        return(fk_fields)


    def ListDataFields(self):
        # retrieve all columns which make an entry unique.

        logging_columns = ["log_user", "log_update", "geometry", "wkb_geometry"] # excluded from checks

        data_fields = [field for field, definition in self.items() \
            if (not definition["primary_key"]) \
                and (field not in logging_columns) \
            ]

        return(data_fields)


    def GetCreateString(self, drop = True):
        # prepare the string to create this table

        # a start
        # the `standard_conforming_strings` parameter has to do with escape chars and backslashes
        # which might appear in the `comment` field. Actually, default is ON, but better safe here.
        create_string = f"""
            SET standard_conforming_strings = ON;
            -- SET search_path TO pg_catalog,public,"{self.schema}";
        """

        # permanent destruction
        if drop:
            create_string += f"""
                DROP TABLE IF EXISTS {self.NameString()} CASCADE;
            """

        # the basic create string, wrapped with others in a BEGIN;COMMIT; block.
        create_string += f"""
            BEGIN;
            CREATE TABLE {self.NameString()}();
        """

        # table comment
        create_string += f"""
            COMMENT ON TABLE {self.NameString()} IS E'{self.comment}';
        """

        # the table geometry is special:
        #     standards require an `fid` pk and a geometry reference
        # TODO: other geometry types
        has_geometry = not PD.isna(self.geometry)
        if has_geometry:
            create_string += GetGeometryString(self.schema, self.table, self.geometry)

            # read users require sequence USAGE to be able to update.
            for user in [self.owner] + self.read_access.split(","):
                create_string += f"""
                    GRANT USAGE ON SEQUENCE "{self.schema}"."{self.table}_ogc_fid_seq" TO {user};
                """

            create_string += f"""
                GRANT SELECT ON SEQUENCE "{self.schema}"."{self.table}_ogc_fid_seq" TO monkey;
            """

        # each column gets its own creation lines
        for col, params in self.items():

            # TODO: currently, geometry column comment is skipped
            if PD.isna(params["datatype"]):
                continue

            create_string += ColumnString(self.schema, self.table, col, params, no_pk = has_geometry)


        # extra constraints and notes
        if not PD.isna(self.constraint):
            create_string += self.constraint + "\n"
        if not PD.isna(self.freesql):
            create_string += self.freesql + "\n"

        # finally, commit what you did `BEGIN;` above.
        create_string += f"""
            COMMIT;
        """

        # some keys are linked to sequences, so that they get auto-increments centrally
        for col, params in self.items():
            # skip empty or False
            if PD.isna(params["sequence"]) or (not params["sequence"]):
                continue

            # append sequence string
            create_string += SequenceString(self.schema, self.table, col, self.owner)


            # read users require sequence USAGE to be able to update.
            for user in self.read_access.split(","):
                create_string += f"""
                    GRANT USAGE ON SEQUENCE "{self.schema}"."seq_{col}" TO {user};
                """

            create_string += f"""
                GRANT SELECT ON SEQUENCE "{self.schema}"."seq_{col}" TO monkey;
            """

        # foreign keys link to other tables
        for col, params in self.items():
            fk = params["foreign_key"]
            if PD.isna(fk):
                continue # skip non-fk's

            # append the create string
            create_string += ForeignKeyString(self.schema, self.table, col, fk)


        # to finish up, grants:
        #   read access
        for reader in self.read_access.split(","):
            create_string += GrantPermissionString(self.schema, self.table, reader, "SELECT")

        #   write access
        if not PD.isna(self.write_access):
            for editor in self.write_access.split(","):

                # https://www.postgresql.org/docs/current/sql-grant.html
                for role in ["INSERT", "UPDATE", "DELETE"]:
                    create_string += GrantPermissionString(self.schema, self.table, editor, role)

        # return the whole shabang
        return(create_string.replace("    ", ""))

    # /GetCreateString


    def QueryData(self, db_connection: DatabaseConnection) -> None:
        # query the current content of this table from the database

        if not db_connection.HasTable(self.table, schema = self.schema):
            WRN.warn(f"Table {self.schema}.{self.table} not found on the server.", RuntimeWarning)
            self.data = None
            return
        # print(self.schema, self.table)
        # print(PD.isna(self.geometry))
        if PD.isna(self.geometry):
            self.data = PD.read_sql_table( \
                self.table, \
                schema = self.schema, \
                con = db_connection.connection \
            )
        else:
            query = f"""
                SELECT *
                FROM {self.NameString()};
            """

            self.data = GPD.read_postgis( \
                query, \
                con = db_connection.connection, \
                geom_col = "wkb_geometry" \
                )

        # print(self.data)

# /class dbTable


def CreateTable(db_connection, table_meta: dbTable, verbose = True, dry = False):
    # creates a table, based on the table object

    table_creation = table_meta.GetCreateString()
    if not dry:
        ExecuteSQL(db_connection, table_creation, verbose = verbose)
    elif verbose:
        # ... or just print, in case of a dry run.
        print(create_string)


class Database(dict):
    def __init__(self,
                 structure_folder = "./db_structure",
                 definition_csv: str = "TABLES.csv",
                 lazy_creation: bool = True,
                 lazy_dataloading: bool = True,
                 db_connection: DatabaseConnection = None,
                 tabula_rasa: bool = False
                 ):

        if definition_csv is None:
            raise IOError("please provide a filename with TABLES definitions.")

        # read in the table definitions
        self.structure_folder = PL.Path(structure_folder)
        definitions = PD.read_csv(self.structure_folder/definition_csv)
        self.tabula_rasa = tabula_rasa

        # generate all tables (first only in Python)
        for _, tabledef in definitions.iterrows():
            nm = tabledef["table"]
            self[nm] = dbTable(tabledef.to_dict(), self.structure_folder)

        # store how tables are linked to each other
        self.GetDatabaseRelations(storage_path = self.structure_folder/"table_relations.conf")

        if (db_connection is not None) and (not lazy_creation):
            # perform all the database creation action at once
            self.PersistData(db_connection)
            self.CreateSchema(db_connection)
            self.CreateTables(db_connection)
            self.CreateViews(db_connection)
            self.ExPostTasks(db_connection)
            self.RestoreData(db_connection)

        if (db_connection is not None) and (not lazy_dataloading):
            self.QueryAllExistingData(db_connection)



    def GetSchemas(self) -> set:
        # retrieve a list of schemas, even before \dn+ is possible
        return set([tbl.schema for tbl in self.values()])


    def GetTables(self, include_excluded = False) -> list:
        # generate a list of non-excluded tables
        for table in self.values():
           if (float(table.excluded) == 1.0) \
                and (not include_excluded):
               continue
           yield(table)


    def PersistData(self, db_connection: DatabaseConnection) -> None:

        ### dump all data, for safety
        now = TI.strftime('%Y%m%d%H%M', TI.localtime())
        db_label = db_connection.config['database']
        db_connection.DumpAll(target_filepath = f"dumps/db_{db_label}_recreation_{now}.sql", user = "monkey")

        if self.tabula_rasa:
            conf_string = f"Oh greatest of computers, please clear {db_label}!"
            input_string = input("\n".join([
                    "WARNING:",
                    "Recreating BLANK, i.e. without data recovery.",
                    f"Type '{conf_string}' to confirm: \n"
                ]))

            shutup_check = (input_string.lower() == 'shut up, just do it.') \
               or (input_string.lower() == 'shut up, just do it!')

            if (input_string != conf_string) and not shutup_check:
                raise(IOError("Confirmation failed, will not tablua rasa the database."))

            if shutup_check:
                print("Okay, okay. You asked for it.")
                TI.sleep(2)
                return

        # store data of persistent tables
        for table in self.GetTables():
            # print(table.persistent, (float(table.persistent) == 1.0))
            if (float(table.persistent) == 1.0):
                table.QueryData(db_connection)



    def RestoreData(self, db_connection: DatabaseConnection) -> None:
        # store data of persistent tables
        for table in self.GetTables():

            # table backup may not be required
            if not (float(table.persistent) == 1.0):
                continue

            # ... or table data was not queried
            if table.data is None:
                continue

            # ... or table was empty
            if table.data.shape[0] == 0:
                continue

            # # table.data = table.data.sample(5)
            # print(f"restoring {table.schema}.{table.table} with {table.geometry} - {table.data.shape}")
            # print(table.data)

            if PD.isna(table.geometry):
                table.data.to_sql( \
                    table.table, \
                    schema = table.schema, \
                    con = db_connection.connection, \
                    index = False, \
                    if_exists = "append", \
                    method = "multi" \
                )

            else:
                # different upload for geopandas data
                # https://stackoverflow.com/a/43375829 <- for future reference
                # https://geopandas.org/en/stable/docs/reference/api/geopandas.GeoDataFrame.to_postgis.html#geopandas.GeoDataFrame.to_postgis
                table.data.to_postgis( \
                    table.table, \
                    schema = table.schema, \
                    con = db_connection.connection, \
                    index = False, \
                    if_exists = "append" \
                )

    def CreateSchema(self, db_connection: DatabaseConnection) -> None:
        # create all schema's from the SCHEMA definition file
        CreateSchema(db_connection, self.structure_folder/"SCHEMA.csv", selection = self.GetSchemas())


    def CreateTables(self, db_connection: DatabaseConnection, verbose: bool = True) -> None:
        # create all tables defined int this database

        for table in self.GetTables():
            # execution order matters! (luckily, dicts have become order persistent)
            create_string = table.GetCreateString()
            ExecuteSQL(db_connection, create_string, verbose = verbose)


    def CreateViews(self, db_connection: DatabaseConnection, verbose: bool = True) -> None:
        # create views

        # views are designed in the `VIEWS` table
        views = PD.read_csv(self.structure_folder/"VIEWS.csv")
        views["excluded"] = views["excluded"].astype(bool)

        # loop views
        for view_id, view in views.iterrows():
            # print(view["excluded"], bool(view["excluded"]))
            if PD.isna(view["query"]) or view["excluded"]:
                continue # skip empty (when in prep)

            view_command = f""" """ # reset command

            view_label = f""" "{view["schema"]}"."{view["view"]}" """


            # create view
            view_command += f"""
                DROP VIEW IF EXISTS {view_label};
                CREATE VIEW {view_label} AS
                {EnsureNestedQuerySpacing(view["query"])};
            """

            for col in ["SELECT", "UPDATE"]:
                if PD.isna(view[col]):
                    continue # skip if empty

                # assign user roles
                for user in view[col].split(","):
                    view_command += f"""
                        GRANT {col} ON {view_label} TO {user};
                    """

            # execute view creation
            ExecuteSQL(db_connection, view_command, verbose = verbose)

            if PD.isna(view["rules"]):
                continue # skip if no rules to apply

            # ececute rules
            # print(view["rules"])
            ExecuteSQL(
                db_connection,
                EnsureNestedQuerySpacing(view["rules"]),
                verbose = verbose
            )


    def ExPostTasks(self, db_connection: DatabaseConnection, verbose = True):
        # apply extra SQL queries after database creation.

        expost = self.structure_folder/"EXPOST.csv"
        commands = PD.read_csv(expost)["sql"].values
        for expost_command in commands:
            ExecuteSQL(
                db_connection,
                EnsureNestedQuerySpacing(expost_command),
                verbose = verbose
            )


    def GetDatabaseRelations(self, storage_path = None):
        # find tables which link to each other
        # format {'dependent_table': {'reference': ['dependent_table::fk', 'reference::pk']}}
        # optional storage in config file

        # variable to store the relations of tables
        self.table_relations = {}
        for table_name in self.keys():
            # primary_key = self[table_name].GetPrimaryKey()

            links = {}
            print(table_name)
            print(self[table_name].ListDependencies())
            for field, dependency in self[table_name].ListDependencies():
                link = dependency.split(".")
                links[link[-2]] = (field, link[-1])
                # format {'table': {'reference': ['table::fk', 'reference::pk']}}

            self.table_relations[table_name] = links

        # optionally store the relations, e.g. for use in R
        if storage_path is not None:

            relation_store = CONF.ConfigParser()
            for table_name, table_relation in self.table_relations.items():
                relation_store[table_name] = table_relation

            with open(storage_path, 'w') as storage_file:
              relation_store.write(storage_file)


    def QueryAllExistingData(self, db_connection, filter_tables = None):
        # load current data of all tables from the database

        for table_name, table in self.items():
            if (filter_tables is not None):
                if (table_name not in filter_tables):
                    continue

            table.QueryData(db_connection)


    def UpdateTableData(
            self,
            db_connection: DatabaseConnection,
            table_key: str,
            new_data: {PD.DataFrame, GPD.GeoDataFrame},
            characteristic_columns: list = None,
            rename_characteristics: dict = None,
            verbose: bool = True
        ) -> None:
        # if `new_data` not passed, previously queried existing data is used

        # TODO: (shortcut) if there is no data in the table,
        #       upload directly (test: protocols right after 020)

        ### (1) dump all data, for safety
        now = TI.strftime('%Y%m%d%H%M', TI.localtime())
        db_connection.DumpAll(target_filepath = f"dumps/safedump_{db_connection.config['database']}_{now}.sql", user = "monkey")

        ### (2) load current data
        dependent_tables = [ \
            dtab \
            for dtab, deps in self.table_relations.items() \
            if table_key in deps.keys() \
        ]

        self.QueryAllExistingData( \
            db_connection, \
            filter_tables = [table_key] + dependent_tables \
        )

        ### (3) store key lookup of dependent table
        lookups = {}
        for deptab in dependent_tables:
            dependent_key, reference_key = self.table_relations[deptab][table_key]
            # print (deptab, dependent_key, "->", table_key, reference_key)

            link_query = f"""
                SELECT
                    {",".join(self[deptab].GetPrimaryKey())}, {dependent_key}
                FROM {self[deptab].NameString()};
            """

            lookups[deptab] = PD.read_sql( \
                link_query, \
                con = db_connection.connection \
            ).astype("Int64")

            # print(lookups[deptab])

        ### (4) retrieve old data
        if characteristic_columns is None:
            characteristic_columns = self[table_key].ListDataFields()
        else:
            # only those which are real columns of the data frame
            characteristic_columns = [
                col for col in self[table_key].keys()
                if col in characteristic_columns
                ]



        pk = list(self[table_key].GetPrimaryKey())

        old_data = self[table_key].data.loc[:, characteristic_columns + pk]
        # old_data.rename(columns = {p: f"{p}_old" for p in pk}, inplace = True)

        # case geopandas data
        if PD.isna(self[table_key].geometry):
            # a safety table
            lostrow_data = PD.read_sql_table( \
                table_key, \
                schema = self[table_key].schema, \
                con = db_connection.connection \
            ).set_index(pk, inplace = False)

        else:
            query = f"""
                SELECT *
                FROM {self[table_key].NameString()};
            """

            lostrow_data = GPD.read_postgis( \
                query, \
                con = db_connection.connection, \
                geom_col = "wkb_geometry" \
            ).set_index(pk, inplace = False)

        # print(lostrow_data)

        ### (5) UPLOAD/replace the data
        # (necessary to get the correct keys)
        # actually, SQLAlchemy cannot drop the table,
        # so we manually delete the content

        if rename_characteristics is not None:
            # adjust some names in the "new data"
            # to match the server logic.
            # TODO (not tested!)
            new_data.rename(columns = rename_characteristics, inplace = True)

        testing = False
        if not testing:
            # DELETE existing data
            ExecuteSQL(
                db_connection,
                f"""
                DELETE FROM {self[table_key].NameString()}
                """,
                verbose = verbose
            )


            # INSERT new data, appending the empty table
            #    (to make use of the "ON DELETE SET NULL" rule)
            if PD.isna(self[table_key].geometry):
                new_data.to_sql( \
                    table_key, \
                    schema = self[table_key].schema, \
                    con = db_connection.connection, \
                    index = False, \
                    if_exists = "append", \
                    method = "multi" \
                )
            else:
                # TODO: (test) case geopandas data
                # https://stackoverflow.com/a/43375829 <- for future reference
                # https://geopandas.org/en/stable/docs/reference/api/geopandas.GeoDataFrame.to_postgis.html#geopandas.GeoDataFrame.to_postgis
                new_data.to_postgis( \
                    table_key, \
                    schema = self[table_key].schema, \
                    con = db_connection.connection, \
                    index = False, \
                    if_exists = "append" \
                )

        self[table_key].QueryData(db_connection)
        new_redownload = self[table_key].data.loc[:, characteristic_columns + pk]

        old_data.set_index(characteristic_columns, inplace = True)
        new_redownload.set_index(characteristic_columns, inplace = True)

        # print(old_data)
        # print(new_redownload)
        pk_lookup = old_data.join(
            new_redownload,
            how = "left",
            lsuffix = "_old",
            rsuffix = ""
        )

        # print(pk_lookup)
        pk_lookup.set_index([f"{p}_old" for p in pk], inplace = True)
        # print(pk_lookup.rename(
        #             columns = {reference_key: dependent_key},
        #             inplace = False
        #         ))

        # warn about NA pk_new
        not_found = pk_lookup.loc[PD.isna(pk_lookup).any(axis = 1), :]
        lost_rows = lostrow_data.loc[not_found.index.values, :]

        if lost_rows.shape[0] > 0:
            WRN.warn("some previous data rows were not found back.", RuntimeWarning)
            print(lost_rows)
            lost_rows.to_csv(f"dumps/lostrows_{table_key}_{now}.csv")


        ### UPDATE dependent tables
        for deptab, lookup in lookups.items():
            dependent_key, reference_key = self.table_relations[deptab][table_key]
            # print(dependent_key, reference_key)
            look = lookup.join(
                pk_lookup.rename(
                    # columns = {reference_key: dependent_key},
                    columns = {dependent_key: reference_key},
                    inplace = False
                ),
                how = "left",
                lsuffix = "_old", rsuffix = "",
                on = dependent_key
            )

            # print(look)
            look[pk] = look[pk].astype("Int64")
            # print(look) # so far, so good!

            dep_pk = list(self[deptab].GetPrimaryKey())

            # dump-store look
            key_replacement = look.loc[:, dep_pk + pk]
            key_replacement.to_csv(f"dumps/lookup_{now}_{table_key}_{deptab}.csv")

            # key_replacement = key_replacement.sample(5) # testing
            # print(key_replacement) #

            # UPDATE table by pk
            update_command = f""" BEGIN; """
            # print ("dep_pk", dep_pk)
            # print ("dependent_key", dependent_key)
            if len(dep_pk) > 1:
                # I think this should never happen: postgres forces 1 pk
                raise(IOError("There is more than one key column; functionality not implemented yet!"))

            row_update_values = []
            for rowkey, replace_fk in key_replacement.iterrows():

                if PD.isna(replace_fk[reference_key]):
                    val = "NULL"
                else:
                    val = f"{replace_fk[reference_key]}"

                update_command += f"""
                    UPDATE {self[deptab].NameString()}
                      SET {dependent_key} = {val}
                      WHERE {dep_pk[0]} = {replace_fk[dep_pk].values[0]}
                    ;
                """

            update_command += f""" COMMIT; """

            # print(update_command)
            ExecuteSQL(
                db_connection,
                update_command,
                verbose = verbose
            )

    # TODO: (bonus) another function
    #       to retain table content upon re-upload based on characteristic columns?
    #       (UPDATE instead of INSERT; diff-like)
    #
    # TODO: analogous to R: characteristic_columns.

    # /UpdateTableData
# /class Database


if __name__ == "__main__":
    # WriteExampleConfig(config_filename = "postgis_server.conf")

    # srv = ReadSQLServerConfig(config_filename = "inbopostgis_server.conf")
    # connstr = ConfigToConnectionString(srv)
    # print(connstr)

    base_folder = PL.Path("./")
    ODStoCSVs(base_folder/"loceval_dev_dbstructure.ods", base_folder/"devdb_structure")


    """ # known error:
    psycopg2.errors.ForeignKeyViolation:
    insert or update on table "ExtraVisits"
    violates foreign key constraint "fk_samplelocations_extravisits"
    DETAIL:
    Key (samplelocation_id)=(3636) is not present in table "SampleLocations".
    """

    db = Database( \
        structure_folder = "./devdb_structure", \
        definition_csv = "TABLES.csv", \
        lazy_creation = True, \
        lazy_dataloading = True, \
        tabula_rasa = True
    )
    # for k, v in db.items():
    #     print('#'*16, k, '#'*16)
    #     print(v)
    #
    # db["LocationCalendar"].GetDependencies()
    # db.GetDatabaseRelations()

    if True:
        db_connection = None
        db_connection = ConnectDatabase( \
            "inbopostgis_server.conf", \
            connection_config = "inbopostgis-dev", \
            database = "loceval_dev" \
           )

        # PD.read_sql_table("Protocols", schema = "metadata", con = db_connection.connection).to_csv("dumps/Protocols.csv", index = False)
        # PD.read_sql_table("TeamMembers", schema = "metadata", con = db_connection.connection).to_csv("dumps/TeamMembers.csv", index = False)

        # db.UpdateTableData( \
        #     db_connection, \
        #     "Protocols", \
        #     new_data = PD.read_csv("dumps/Protocols_new.csv") \
        #     # new_data = PD.read_csv("dumps/Protocols_old.csv") \
        # )
        # db.UpdateTableData( \
        #     db_connection, \
        #     "Protocols", \
        #     # new_data = PD.read_csv("dumps/Protocols_new.csv") \
        #     new_data = PD.read_csv("dumps/Protocols_old.csv") \
        # )
        # db.UpdateTableData( \
        #     db_connection, \
        #     "TeamMembers", \
        #     new_data = PD.read_csv("dumps/TeamMembers_new.csv") \
        # )



    if True:
        pass
        db.PersistData(db_connection)
        db.CreateSchema(db_connection)
        db.CreateTables(db_connection)
        db.CreateViews(db_connection)
        db.ExPostTasks(db_connection)
        db.RestoreData(db_connection)



# SET search_path TO public,speeltuin;
