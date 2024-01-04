# %%

import os

os.environ["USE_PYGEOS"] = "0"
import time
import yaml
from src import db_functions as dbf
from src import preprocess_functions as prep_func
import geopandas as gpd
import pandas as pd
from itertools import groupby

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
# Perform initial matching
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

print("Matching done!")
print("Process matching starting...")

# %%
# Process matches

dbf.run_query_pg(
    "sql/03i_process_matches.sql",
    connection,
    success="Query successful!",
    fail="Query failed!",
    commit=True,
    close=False,
)

print("First preprocessing complete!")
print("Continuing with processing of incomplete matches....")

# %%
# Process undecided segments
connection = dbf.connect_pg(db_name, db_user, db_password, db_port, db_host=db_host)

# Undecided segments and edges
q = "SELECT * FROM matching_geodk_osm._undecided_segments"
undecided_segments = gpd.GeoDataFrame.from_postgis(q, connection, crs="EPSG:25832")

q = "SELECT * FROM matching_geodk_osm._undecided_groups"
undecided_groups = pd.read_sql(q, connection)

# Group adjacent identical matching vales
undecided_groups["group_matching"] = undecided_groups["matched_count"].apply(
    lambda x: [list(t) for z, t in groupby(x)]
)

undecided_groups["group_matching"] = undecided_groups.group_matching.apply(
    lambda x: prep_func.standardize_matched_segments(x)
)

undecided_groups["group_matching"] = undecided_groups.group_matching.apply(
    lambda x: prep_func.merge_similar_lists(x)
)

undecided_groups["len"] = undecided_groups.group_matching.apply(lambda x: len(x))

edges_to_split = undecided_groups.loc[undecided_groups.len == 2]

new_edges = prep_func.split_edges(edges_to_split, undecided_segments)

# Export data
print("Saving data to Postgres!")

engine = dbf.connect_alc(db_name, db_user, db_password, db_port=db_port)

table_name = "_decided_segments"
dbf.to_postgis(
    geodataframe=new_edges,
    table_name=table_name,
    engine=engine,
    schema="matching_geodk_osm",
)

q = f"SELECT segment_ids, id_osm, matched FROM matching_geodk_osm._decided_segments LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)

# %%
# Add undecided/split edges to edge table
# identify matched edges

connection = dbf.connect_pg(db_name, db_user, db_password, db_port, db_host=db_host)

q = "sql/03j_identify_matched_edges.sql"

dbf.run_query_pg(
    q,
    connection,
    success="Query successful!",
    fail="Query failed!",
    commit=True,
    close=False,
)
print(f"Split edges processed!")

# %%
# Rebuild topology

connection = dbf.connect_pg(db_name, db_user, db_password, db_port, db_host=db_host)

q = "sql/03k_rebuild_topology.sql"

dbf.run_query_pg(
    q,
    connection,
    success="Query successful!",
    fail="Query failed!",
    commit=True,
    close=False,
)
print(f"Topology rebuild")


# %%
# finish processing

queries = [
    "sql/03l_close_matching_gaps.sql",
    "sql/03m_transfer_geodk_attributes.sql",
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

print("Processing done!")

connection.close()
# %%
print("Start", starttime)
print("Endtime", time.ctime())

# %%
