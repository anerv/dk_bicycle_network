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

queries = [
    "sql/04a_add_additional_cycling_info.sql",
    "sql/04b_interpolate_missing_tags.sql",
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