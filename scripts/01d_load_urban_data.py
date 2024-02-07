# %%
import geopandas as gpd
import pandas as pd
import yaml

from src import db_functions as dbf

with open(r"../config.yml") as file:
    parsed_yaml_file = yaml.load(file, Loader=yaml.FullLoader)

    crs = parsed_yaml_file["CRS"]

    urban_fp1 = parsed_yaml_file["urban_fp1"]
    urban_fp2 = parsed_yaml_file["urban_fp2"]

    db_name = parsed_yaml_file["db_name"]
    db_user = parsed_yaml_file["db_user"]
    db_password = parsed_yaml_file["db_password"]
    db_host = parsed_yaml_file["db_host"]
    db_port = parsed_yaml_file["db_port"]


print("Settings loaded!")

# %%
# *** READ INPUT DATA ***

all_zones = gpd.read_file(urban_fp1)

assert all_zones.crs == crs

all_zones = all_zones[["zone", "zonestatus", "geometry"]]

all_zones["area_class"] = None
all_zones.loc[all_zones.zonestatus == "Byzone", "area_class"] = "urban"
all_zones.loc[all_zones.zonestatus == "Sommerhusområde", "area_class"] = "summerhouse"

# %%

building_areas = gpd.read_file(urban_fp2)

assert building_areas.crs == crs

building_areas = building_areas.loc[
    building_areas.bebyggelsestype.isin(
        ["bydel", "sommerhusområde", "by", "kolonihave", "industriområde"]
    )
]
building_areas = building_areas[["bebyggelsestype", "geometry"]]

building_areas["area_class"] = None
building_areas.loc[building_areas.bebyggelsestype == "bydel", "area_class"] = "urban"
building_areas.loc[building_areas.bebyggelsestype == "by", "area_class"] = "urban"
building_areas.loc[building_areas.bebyggelsestype == "industriområde", "area_class"] = (
    "industrial"
)
building_areas.loc[building_areas.bebyggelsestype == "kolonihave", "area_class"] = (
    "urban"
)
building_areas.loc[
    building_areas.bebyggelsestype == "sommerhusområde", "area_class"
] = "summerhouse"
# %%
# *** EXPORT ***

print("Saving data to Postgres!")

connection = dbf.connect_pg(db_name, db_user, db_password, db_port)

engine = dbf.connect_alc(db_name, db_user, db_password, db_port=db_port)

dbf.to_postgis(geodataframe=all_zones, table_name="urban_zones", engine=engine)

q = f"SELECT zone, zonestatus FROM urban_zones LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)

dbf.to_postgis(geodataframe=building_areas, table_name="building_areas", engine=engine)

q = f"SELECT bebyggelsestype, area_class FROM building_areas LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)

connection.close()

print("Script 01d complete!")
# %%
