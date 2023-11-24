# %%

import os

os.environ["USE_PYGEOS"] = "0"
import time
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

print("Initializing...")
print("Start", time.ctime())

starttime = time.ctime()

# %%
connection = dbf.connect_pg(db_name, db_user, db_password, db_port, db_host=db_host)

queries = [
    "sql/matching/01_prepare_data.sql",
    "sql/matching/02_create_segments_bike.sql",
    "sql/matching/03_find_candidates_bike.sql",
    "sql/matching/04_find_best_match_bike.sql",
    "sql/matching/05_find_unmatched_geodk_segments.sql",
    "sql/matching/06_create_segments_no_bike.sql",
    "sql/matching/07_find_candidates_no_bike.sql",
    "sql/matching/08_find_best_matches_no_bike.sql",
]

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

print("DONE!!!!")
print("Start", starttime)
print("Endtime", time.ctime())


# %%
