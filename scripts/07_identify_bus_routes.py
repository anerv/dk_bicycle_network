# %%
# Identify bus routes not mapped with a relation

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

connection = dbf.connect_pg(db_name, db_user, db_password, db_port, db_host=db_host)

dbf.run_query_pg(
    "sql/07_add_bus_routes.sql",
    connection,
    success="Query successful!",
    fail="Query failed!",
    commit=True,
    close=False,
)

q = f"SELECT highway, bus_route FROM osm_road_edges WHERE bus_route IS TRUE LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)

print("Bus routes identified!")

connection.close()

with open("vacuum_analyze.py") as f:
    exec(f.read())

print("Script 07 complete!")

# %%
