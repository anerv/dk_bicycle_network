# %%
import geopandas as gpd
import pandas as pd
import yaml

from src import db_functions as dbf
from src import preprocess_functions as prep

with open(r"../config.yml") as file:
    parsed_yaml_file = yaml.load(file, Loader=yaml.FullLoader)

    crs = parsed_yaml_file["CRS"]

    urban_fp = parsed_yaml_file["urban_fp"]

    db_name = parsed_yaml_file["db_name"]
    db_user = parsed_yaml_file["db_user"]
    db_password = parsed_yaml_file["db_password"]
    db_host = parsed_yaml_file["db_host"]
    db_port = parsed_yaml_file["db_port"]


print("Settings loaded!")

# *** READ INPUT DATA ***

all_zones = gpd.read_file(urban_fp)

assert all_zones.crs == crs

all_zones = all_zones[["zone", "zonestatus", "geometry"]]

# %%
# *** EXPORT ***

print("Saving data to Postgres!")

connection = dbf.connect_pg(db_name, db_user, db_password, db_port)

engine = dbf.connect_alc(db_name, db_user, db_password, db_port=db_port)

dbf.to_postgis(geodataframe=all_zones, table_name="urban_zones", engine=engine)

q = f"SELECT zone, zonestatus FROM urban_zones LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)

connection.close()
# %%
