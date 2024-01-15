# %%

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
queries = [
    "sql/09a_lts_classification.sql",
    "sql/09b_lts_intersections.sql",
    "sql/09c_lts_crossings.sql",
]
connection = dbf.connect_pg(db_name, db_user, db_password, db_port, db_host=db_host)

for i, q in enumerate(queries):
    print(f"Running step {i+1}...")
    dbf.run_query_pg(
        q,
        connection,
        success="Query successful!",
        fail="Query failed!",
        commit=True,
        close=False,
    )
    print(f"Step {i+1} done!")

# %%

q = f"SELECT id, highway FROM osm_road_edges WHERE lts = 1 LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)

q = f"SELECT id, lts FROM osm_road_edges WHERE lts = 3 LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)

connection.close()
# %%
