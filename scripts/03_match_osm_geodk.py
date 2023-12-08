# %%

import os

os.environ["USE_PYGEOS"] = "0"
import time
import yaml
from src import db_functions as dbf
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
connection = dbf.connect_pg(db_name, db_user, db_password, db_port, db_host=db_host)

# queries = [
#     "sql/03a_prepare_data.sql",
#     "sql/03b_create_segments.sql",
#     "sql/03c_find_candidates_bike.sql",
#     "sql/03d_find_best_match_bike.sql",
#     "sql/03e_find_unmatched_geodk_segments.sql",
#     "sql/03g_find_candidates_no_bike.sql",
#     "sql/03h_find_best_matches_no_bike.sql",
# ]


# for i, q in enumerate(queries):
#     print(f"Running step {i+1}...")
#     dbf.run_query_pg(
#         q,
#         connection,
#         success="Query successful!",
#         fail="Query failed!",
#         commit=True,
#         close=False,
#     )
#     print(f"Step {i+1} done!")


# %%
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
print("Continuing with matching of edges....")

# %%
# Process undecided segments
connection = dbf.connect_pg(db_name, db_user, db_password, db_port, db_host=db_host)

# Undecided segments and edges
q = "SELECT * FROM matching_geodk_osm._undecided_segments"
undecided_segments = gpd.GeoDataFrame.from_postgis(q, connection, crs="EPSG:25832")

q = "SELECT * FROM matching_geodk_osm._undecided_groups"
undecided_groups = pd.read_sql(q, connection)

# %%
# Group adjacent identical matching vales
undecided_groups["group_matching"] = undecided_groups["matched_count"].apply(
    lambda x: [list(t) for z, t in groupby(x)]
)


# %%
def standardize_matched_segments(nested_list):
    for i, l in enumerate(nested_list):
        if len(l) == 1:
            # find opposite value:
            if l[0] == False:
                new_val = True
            else:
                new_val = False
            # Add to list before or after
            # If at the enf of nested list, add to group before
            if i == len(nested_list) - 1:
                nested_list[i - 1].append(new_val)
            else:
                nested_list[i + 1].append(new_val)

            # Remove L from list
            nested_list.pop(i)

    return nested_list


def merge_similar_lists(nested_list):
    # Assumes nested lists with identical values
    i = 0
    while i < len(nested_list) - 1:
        # for i in range(len(nested_list) - 1):
        if nested_list[i][0] == nested_list[i + 1][0]:
            nested_list[i + 1] = nested_list[i] + nested_list[i + 1]
            nested_list.pop(i)

        i += 1

    return nested_list


# %%

undecided_groups["group_matching"] = undecided_groups.group_matching.apply(
    lambda x: standardize_matched_segments(x)
)

undecided_groups["group_matching"] = undecided_groups.group_matching.apply(
    lambda x: merge_similar_lists(x)
)

# %%
undecided_groups["len"] = undecided_groups.group_matching.apply(lambda x: len(x))

# %%
# If it can be divided into two groups, it needs to be split
undecided_groups["split"] = None
undecided_groups.loc[undecided_groups.len == 2, "split"] = True

# %%
# TODO: Mark edges as matched (update matched final) based on grouped edges
# Including surface info etc

# TODO: split
# for group in now-decided groups:
# get indexes for True and False:
# Get ids for corresponding segments
# Get segment geometries
# Merge them into one line (both true and false)
# get info on surfac etc.
# store to a new gdf with segment id(?) and org id_osm and info on matched and not matched and surface/category info

# ADD new geometries to osm_road_edges tables while marking them as matched or unmatched
# QUESTION: TODO: what to do with ids? Create two new UNIQUE IDS - how?
# Del org non-split geometries
# Rebuild topology
#
# %%


print("Start", starttime)
print("Endtime", time.ctime())


# %%


# -- THEN TRANSFER TO SEGMENTS
# -- group osm_segs by org_id
# -- if more than XXX segs are matched -- mark as matched?
# -- store in new column for osm roads
# -- make new bicycle infra column
# --
# -- TODO: CLOSE GAPS
