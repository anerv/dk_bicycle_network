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

# %%
connection = dbf.connect_pg(db_name, db_user, db_password, db_port, db_host=db_host)

dbf.run_query_pg(
    "sql/07_assign_muni_urban.sql",
    connection,
    success="Query successful!",
    fail="Query failed!",
    commit=True,
    close=False,
)

# %%
# Run last query here because of formatting issue with dist operator <->
q = """WITH urban_selection AS (
    SELECT
        *
    FROM
        urban_polygons_8
    WHERE
        urban_code > 10
)
UPDATE
    osm_road_edges o
SET
    urban = (
        SELECT
            urban
        FROM
            urban_selection u
        ORDER BY
            u.geometry <-> o.geometry
        LIMIT
            1
    )
WHERE
    o.urban IS NULL;"""

dbf.run_query_pg(
    q,
    connection,
    success="Query successful!",
    fail="Query failed!",
    commit=True,
    close=False,
)
# %%
q = f"SELECT highway, urban, municipality FROM osm_road_edges LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)

connection.close()

# %%
