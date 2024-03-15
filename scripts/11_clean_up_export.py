# %%

import os
import geopandas as gpd

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

dbf.run_query_pg("sql/11a_clean_up.sql", connection)

print("Clean up done!")

dbf.run_query_pg("sql/11b_compute_oneway.sql", connection)

print("Identified oneway roads and bicycle infrastructure!")

dbf.run_query_pg("sql/11c_export.sql", connection)

connection.close()

print("Export views ready!")

# connection = dbf.connect_pg(db_name, db_user, db_password, db_port, db_host=db_host)

engine = dbf.connect_alc(db_name, db_user, db_password, db_port=db_port)

q = "SELECT * FROM osm_edges_export;"

edges = gpd.GeoDataFrame.from_postgis(q, engine, geom_col="geometry")

edges.to_parquet("../data/processed/osm_road_edges.parquet")

del edges

q = "SELECT * FROM osm_nodes_export;"

nodes = gpd.GeoDataFrame.from_postgis(q, engine, geom_col="geometry")

nodes.to_parquet("../data/processed/osm_road_nodes.parquet")

connection.close()

print("Tables exported!")

print("Script 11 complete!")
# %%
