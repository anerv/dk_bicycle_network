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
    "sql/03a_prepare_data.sql",
    "sql/03b_create_segments.sql",
    "sql/03c_find_candidates_bike.sql",
    "sql/03d_find_best_match_bike.sql",
    "sql/03e_find_unmatched_geodk_segments.sql",
    "sql/03g_find_candidates_no_bike.sql",
    "sql/03h_find_best_matches_no_bike.sql",
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
#
# -- TODO: TRANSFER vejkategori and surface TO OSM SEGMENTS

# transfer surface and kategori to geodk matches
# find matched osm segments!

# -- THEN TRANSFER TO SEGMENTS
# -- group osm_segs by org_id
# -- if more than XXX segs are matched -- mark as matched?
# -- store in new column for osm roads
# -- make new bicycle infra column
# --
# -- TODO: CLOSE GAPS
