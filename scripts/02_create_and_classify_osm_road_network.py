# %%

# GET OSM ROADS + IDENTIFY OSM BICYCLE INFRASTRUCTURE

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

print("Creating OSM road table...")

connection = dbf.connect_pg(db_name, db_user, db_password, db_port, db_host=db_host)

queries = [
    "sql/02a_create_osm_road_table.sql",
    "sql/02b_classify_cycling_infrastructure.sql",
]

for i, q in enumerate(queries):
    print(f"Running step {i+1}...")
    result = dbf.run_query_pg(q, connection)
    if result == "error":
        print("Please fix error before rerunning and reconnect to the database")
        break

    print(f"Step {i+1} done!")


connection = dbf.connect_pg(db_name, db_user, db_password, db_port=db_port)

q = "SELECT osm_id, highway FROM osm_road_edges WHERE bicycle_infrastructure IS TRUE LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)

connection.close()

print("Road table created successfully!")
print("Bicycle infrastructure classified!")

with open("vacuum_analyze.py") as f:
    exec(f.read())

print("Script 02 complete!")
# %%
