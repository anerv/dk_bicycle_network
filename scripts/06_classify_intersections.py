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

connection = dbf.connect_pg(db_name, db_user, db_password, db_port, db_host=db_host)

dbf.run_query_pg("sql/06_classify_intersections.sql", connection)

q = f"SELECT osm_id, intersection_type, geometry FROM nodes LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)


print("Intersections classified!")

connection.close()

with open("vacuum_analyze.py") as f:
    exec(f.read())

print("Script 06 complete!")
# %%
