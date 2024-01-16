# %%

import os

os.environ["USE_PYGEOS"] = "0"

import yaml
from src import db_functions as dbf

with open(r"../config.yml") as file:
    parsed_yaml_file = yaml.load(file, Loader=yaml.FullLoader)

    db_name = parsed_yaml_file["db_name"]
    db_user = parsed_yaml_file["db_user"]
    db_password = parsed_yaml_file["db_password"]
    db_host = parsed_yaml_file["db_host"]
    db_port = parsed_yaml_file["db_port"]


print("Settings loaded!")

# %%
connection = dbf.connect_pg(db_name, db_user, db_password, db_port, db_host=db_host)

dbf.run_query_pg(
    "sql/10a_clean_up.sql",
    connection,
    success="Query successful!",
    fail="Query failed!",
    commit=True,
    close=False,
)

connection.close()

print("Clean up done!")

# %%
connection = dbf.connect_pg(db_name, db_user, db_password, db_port, db_host=db_host)

dbf.run_query_pg(
    "sql/10b_export.sql",
    connection,
    success="Query successful!",
    fail="Query failed!",
    commit=True,
    close=False,
)

connection.close()

print("Export views ready!")

#%%
connection = dbf.connect_pg(db_name, db_user, db_password, db_port, db_host=db_host)

q = "SELECT * FROM osm_edges_export;"

edges = dbf.run_query_pg(
    q,
    connection,
    success="Query successful!",
    fail="Query failed!",
    commit=True,
    close=False,
)

edges.to_parquet("../data/processed/osm_road_edges.parquet")

del edges

q = "SELECT * FROM osm_nodes_export;"

nodes = dbf.run_query_pg(
    q,
    connection,
    success="Query successful!",
    fail="Query failed!",
    commit=True,
    close=False,
)

nodes.to_parquet("../data/processed/osm_road_nodes.parquet")

connection.close()

print("Tables exported!")
#%%