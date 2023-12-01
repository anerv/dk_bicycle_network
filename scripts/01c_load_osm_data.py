# %%
import yaml
import subprocess
import os
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

# %%
connection = dbf.connect_pg(db_name, db_user, db_password, db_port=db_port)

q = "SELECT osm_id, highway FROM planet_osm_roads WHERE highway IS NOT NULL LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)

connection.close()

# %%
# Load OSM data with correct topology to use for OSM routing using osm2po
subprocess.run(
    f"java -jar /Users/anev/Library/CloudStorage/Dropbox/ITU/repositories/dk_bicycle_network/osm2po/osm2po-5.5.5/osm2po-core-5.5.5-signed.jar cmd=c prefix=dk {osm_fp}",
    shell=True,
    check=True,
)

# %%
os.rename(
    "/Users/anev/Library/CloudStorage/Dropbox/ITU/repositories/dk_bicycle_network/scripts/dk/",
    "/Users/anev/Library/CloudStorage/Dropbox/ITU/repositories/dk_bicycle_network/scripts/dk_osm2po/",
)
# %%
# import into postgres
subprocess.run(
    f"psql -h {db_host} -p 5432 -U postgres -d {db_name} -q -f /Users/anev/Library/CloudStorage/Dropbox/ITU/repositories/dk_bicycle_network/scripts/dk_osm2_po/dk_2po_4pgr.sql",
    shell=True,
    check=True,
)
# %%
connection = dbf.connect_pg(db_name, db_user, db_password, db_port=db_port)

q = "SELECT osm_id, source, target, osm_name FROM dk_2po_4pgr WHERE osm_name IS NOT NULL LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)

connection.close()

# %%


# %%
