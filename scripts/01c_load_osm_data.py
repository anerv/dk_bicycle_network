# %%
import yaml
import subprocess
from src import db_functions as dbf

with open(r"../config.yml") as file:
    parsed_yaml_file = yaml.load(file, Loader=yaml.FullLoader)

    osm_fp = parsed_yaml_file["osm_fp"]
    osm_style_file = parsed_yaml_file["osm_style_file"]

    crs = parsed_yaml_file["CRS"]

    db_name = parsed_yaml_file["db_name"]
    db_user = parsed_yaml_file["db_user"]
    db_password = parsed_yaml_file["db_password"]
    db_host = parsed_yaml_file["db_host"]
    db_port = parsed_yaml_file["db_port"]

print("Settings loaded!")

# %%
subprocess.run(
    f"osm2pgsql -c -d {db_name} -U postgres -H localhost --slim --hstore -S {osm_style_file} {osm_fp}",
    shell=True,
    check=True,
)

print("OSM data load complete!")

# osm2pgsql -c -d bike_network -U postgres -H localhost --slim --hstore -S /Users/anev/Library/CloudStorage/Dropbox/ITU/repositories/dk_bicycle_network/resources/default.style /Users/anev/Library/CloudStorage/Dropbox/ITU/repositories/dk_bicycle_network/data/raw/road_networks/denmark-latest.osm.pbf

# %%
connection = dbf.connect_pg(db_name, db_user, db_password, db_port=db_port)

q = "SELECT osm_id, highway FROM planet_osm_roads WHERE highway IS NOT NULL LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)

connection.close()

# %%
