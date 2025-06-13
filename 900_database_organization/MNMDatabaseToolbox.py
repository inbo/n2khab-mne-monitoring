#!/usr/bin/env python3

import atexit as EXIT
import pathlib as PL
import getpass as PWD
import sqlalchemy as SQL
import pandas as PD
import configparser as CONF


def WriteExampleConfig(config_filename = "postgis_server.conf", server_label = "test"):
    # this will create an example config file; with the following content.
    # WARNING: passwords are stored in plain text.
    """
    [test]
    server = localhost
    port = 5439
    user = test
    database = playground
    password = <the password you entered IN PLAIN TEXT>
    """

    config = CONF.ConfigParser()
    config[server_label] = {
        'server': 'localhost',
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


def ReadSQLServerConfig(config_filename = "postgis_server.conf", label = None, **kwargs):
    # will read sql configuration from a text file.

    # parse the config with the config parser
    config = CONF.ConfigParser()
    config.read(config_filename)

    # per default, take first section
    if label is None:
        server_label = config.sections()[0]
    else:
        server_label = label

    # convert to dictionary
    db_configuration = dict(config[label])

    # extra arguments
    for kw, val in kwargs.items():
        db_configuration[kw] = val

    # prompt password
    if 'password' not in db_configuration.keys():
        config[server_label]['password'] = PWD.getpass("password: ")

    return(db_configuration)


def ConfigToConnectionString(config: dict) -> str:
    # concatenate the connection string from a config dict
    # TODO: prompt user to enter missing connection info; store in config

    defaults = {"port": 5439, "server": "localhost"}
    config_relevant = {k: config.get(k, defaults.get(k, None))
                       for k in ["server", "port", "user", "database", "password"]}

    if type(config_relevant["port"]) is not str:
        # ensure port numeric to string
        config_relevant["port"] = f"{config_relevant["port"]:%.0f}"

    conn_str = """postgresql://{user}:{password}@{server}:{port}/{database}""".format(
        **config_relevant
    )

    return(conn_str)


def ConnectDatabase(config_filepath, database, connection_config = None):
    # https://stackoverflow.com/a/42772654
    # user = input("user: ")

    config = ReadSQLServerConfig(config_filepath, label = connection_config, database = database)
    engine = SQL.create_engine(ConfigToConnectionString(config))
    connection = engine.connect()

    EXIT.register(connection.close)

    return(connection)


def ExecuteSQL(db_connection, sql_command, verbose = True) -> None:
    # execute an sql statement, with all the necessary connection management

    if verbose:
        print(sql_command)
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
        print(value)
        if params["datatype"] == "boolean":
            value = str(bool(value)).upper()
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
                ALTER SEQUENCE "{schema}".seq_{sequence_column} OWNER TO {owner};
            """)


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
            , "AS " # note that "AS" without space is in "CASE"\
            , "UPDATE", "ON UPDATE", "INSTEAD" \
            , "LEFT JOIN" \
            , "DISTINCT", "GROUP BY" \
            , "CASE WHEN", "THEN", "ELSE", "END" \
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

    def __init__(self, tabledef: dict, base_folder: PL.Path = PL.Path("./")):
        # | self.schema       | self.table        | self.owner       |
        # | self.read_access  | self.write_access | self.geometry    |
        # | self.constraint   | self.freesql      | self.comment     |

        self.folder = base_folder

        for k, v in tabledef.items():
            setattr(self, k, v)

        self.definition_file = self.folder/f"{self.table}.csv"

        table_definitions = PD.read_csv(self.definition_file)
        for _, datafield in table_definitions.iterrows():
            nm = datafield["column"]
            self[nm] = datafield.to_dict()


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
                DROP TABLE IF EXISTS "{self.schema}"."{self.table}" CASCADE;
            """

        # the basic create string, wrapped with others in a BEGIN;COMMIT; block.
        create_string += f"""
            BEGIN;
            CREATE TABLE "{self.schema}"."{self.table}"();
        """

        # table comment
        create_string += f"""
            COMMENT ON TABLE "{self.schema}"."{self.table}" IS E'{self.comment}';
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

        # each column gets its own creation lines
        for col, params in self.items():
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
                 base_folder = "./",
                 definition_csv: str = "TABLES.csv",
                 lazy_creation: bool = True,
                 db_connection: SQL.Connection = None
                 ):

        if definition_csv is None:
            raise IOError("please provide a filename with TABLES definitions.")

        # read in the table definitions
        self.base_folder = PL.Path(base_folder)
        definitions = PD.read_csv(self.base_folder/definition_csv)
        # print(definitions)

        # generate all tables (first only in Python)
        for _, tabledef in definitions.iterrows():
            nm = tabledef["table"]
            self[nm] = dbTable(tabledef.to_dict(), self.base_folder)

        if (db_connection is not None) and (not lazy_creation):
            # perform all the action at once
            self.CreateSchema(db_connection)
            self.CreateTables(db_connection)
            self.CreateViews(db_connection)
            self.ExPostTasks(db_connection)


    def GetSchemas(self) -> set:
        # retrieve a list of schemas, even before \dn+ is possible
        return set([tbl.schema for tbl in self.values()])

    def CreateSchema(self, db_connection: SQL.Connection) -> None:
        # create all schema's from the SCHEMA definition file
        CreateSchema(db_connection, self.base_folder/"SCHEMA.csv", selection = self.GetSchemas())


    def CreateTables(self, db_connection: SQL.Connection, verbose = True):
        # create all tables defined int this database

        for table in self.values():
            create_string = table.GetCreateString()
            ExecuteSQL(db_connection, create_string, verbose = verbose)

    def CreateViews(self, db_connection: SQL.Connection, verbose = True):
        # create views

        # views are designed in the `VIEWS` table
        views = PD.read_csv(self.base_folder/"VIEWS.csv")

        # loop views
        for view_id, view in views.iterrows():
            if PD.isna(view["query"]):
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
            print(view["rules"])
            ExecuteSQL(
                db_connection,
                EnsureNestedQuerySpacing(view["rules"]),
                verbose = verbose
            )


    def ExPostTasks(self, db_connection: SQL.Connection, verbose = True):
        # apply extra SQL queries after database creation.

        expost = self.base_folder/"EXPOST.csv"
        commands = PD.read_csv(expost)["sql"].values
        for expost_command in commands:
            ExecuteSQL(db_connection, expost_command, verbose = verbose)


if __name__ == "__main__":
    # WriteExampleConfig(config_filename = "postgis_server.conf")

    # srv = ReadSQLServerConfig(config_filename = "inbopostgis_server.conf")
    # connstr = ConfigToConnectionString(srv)
    # print(connstr)

    base_folder = PL.Path("./")
    ODStoCSVs(base_folder/"sandbox_staanbeeldentuin.ods", base_folder/"db_structure")


    db = Database( \
        base_folder = "./db_structure", \
        definition_csv = "TABLES.csv", \
        lazy_creation = True \
    )
    # for k, v in db.items():
    #     print('#'*16, k, '#'*16)
    #     print(v)

    db_connection = None
    db_connection = ConnectDatabase("inbopostgis_server.conf")
    db.CreateSchema(db_connection)
    db.CreateTables(db_connection)
    db.CreateViews(db_connection)
    db.ExPostTasks(db_connection)



# SET search_path TO public,speeltuin;
