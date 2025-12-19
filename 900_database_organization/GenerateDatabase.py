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
        'user': 'test',
        'database': 'playground'
    }

    config[server_label]['password'] = PWD.getpass("password: ")

    with open(config_filename, 'w') as configfile:
      config.write(configfile)


def ReadSQLServerConfig(config_filename = "postgis_server.conf", server_label = None):
    # will read sql configuration from a text file.

    config = CONF.ConfigParser()
    config.read(config_filename)

    if server_label is None:
        server_label = config.sections()[0]

    return(dict(config[server_label]))


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


def ConnectDatabase(config_filepath):
    # https://stackoverflow.com/a/42772654
    # user = input("user: ")

    config = ReadSQLServerConfig(config_filepath)
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
        attributes += [f"""DEFAULT {str(params["default"])}"""]

    # pk
    if (params["primary_key"] is True) and (not no_pk):
        attributes += [f"""PRIMARY KEY"""]

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
    label = f"fk_{fk[0]}_{table}"
    fokey_string = f"""
        -- foreign key {col}
        ALTER TABLE "{schema}"."{table}" DROP CONSTRAINT IF EXISTS {label} CASCADE;
        ALTER TABLE "{schema}"."{table}" ADD CONSTRAINT {label} FOREIGN KEY ({col})
            REFERENCES "{schema}"."{fk[0]}" ({fk[1]}) MATCH SIMPLE
            ON DELETE SET NULL ON UPDATE CASCADE;
    """
    # note the last line: we can delete, and cascade updates
    return(fokey_string)

def GrantPermissionString(schema, table, user, role):
    # parametrized sql string to grant some permission (role) to a user.
    return(f"""
        GRANT {role} ON "{schema}"."{table}" TO {user};
    """)




class dbTable(dict):
    # a class to store all required attributes and functionality
    # to handle a table in the database.

    def __init__(self, tabledef: dict, base_folder: PL.Path = PL.Path("./")):
        # self.schema
        # self.table
        # self.owner
        # self.read_access
        # self.write_access
        # self.geometry
        # self.comment

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

        # each column gets its own creation lines
        for col, params in self.items():
            if PD.isna(params["datatype"]):
                continue

            create_string += ColumnString(self.schema, self.table, col, params, no_pk = has_geometry)

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

        self.base_folder = PL.Path(base_folder)
        definitions = PD.read_csv(self.base_folder/definition_csv)
        # print(definitions)

        for _, tabledef in definitions.iterrows():
            nm = tabledef["table"]
            self[nm] = dbTable(tabledef.to_dict(), self.base_folder)

        if (db_connection is not None) and (not lazy_creation):
            self.CreateSchema(db_connection)
            self.CreateTables(db_connection)


    def GetSchemas(self) -> set:
        return set([tbl.schema for tbl in self.values()])

    def CreateSchema(self, db_connection: SQL.Connection) -> None:
        CreateSchema(db_connection, self.base_folder/"SCHEMA.csv", selection = self.GetSchemas())


    def CreateTables(self, db_connection: SQL.Connection, verbose = True):
        for table in self.values():
            create_string = table.GetCreateString()
            ExecuteSQL(db_connection, create_string, verbose = verbose)



if __name__ == "__main__":
    # WriteExampleConfig(config_filename = "postgis_server.conf")
    # srv = ReadSQLServerConfig(config_filename = "inbopostgis_server.conf")
    # connstr = ConfigToConnectionString(srv)
    # print(connstr)

    db = Database( \
        base_folder = "./db_structure", \
        definition_csv = "TABLES.csv", \
        lazy_creation = True \
    )
    # for k, v in db.items():
    #     print('#'*16, k, '#'*16)
    #     print(v)

    db_connection = ConnectDatabase("inbopostgis_server.conf")
    db.CreateSchema(db_connection)
    db.CreateTables(db_connection)



# SET search_path TO public,speeltuin;
