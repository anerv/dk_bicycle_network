import os

os.environ["USE_PYGEOS"] = "0"
import time
import yaml
from src import db_functions as dbf
from src import preprocess_functions as prep_func
import geopandas as gpd
import pandas as pd
from itertools import groupby

with open(r"../config.yml") as file:
    parsed_yaml_file = yaml.load(file, Loader=yaml.FullLoader)

    db_name = parsed_yaml_file["db_name"]
    db_user = parsed_yaml_file["db_user"]
    db_password = parsed_yaml_file["db_password"]
    db_host = parsed_yaml_file["db_host"]
    db_port = parsed_yaml_file["db_port"]


print("Settings loaded!")

connection = dbf.connect_pg(db_name, db_user, db_password, db_port, db_host=db_host)

dbf.run_query_pg(
    "sql/05a_create_graph.sql",
    connection,
    success="Query successful!",
    fail="Query failed!",
    commit=True,
    close=False,
)

q = f"SELECT * FROM osm_road_edges_vertices_pgr LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)

print("Network vertices created successfully!")
