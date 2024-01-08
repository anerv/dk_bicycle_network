# *** Loading GeoDK data to PostGIS db ***

# %%
import yaml
import subprocess
from src import db_functions as dbf

# %%
with open(r"../config.yml") as file:
    parsed_yaml_file = yaml.load(file, Loader=yaml.FullLoader)

    geodk_fp = parsed_yaml_file["geodk_fp"]
    geodk_id_col = parsed_yaml_file["geodk_id_col"]

    crs = parsed_yaml_file["CRS"]

    db_name = parsed_yaml_file["db_name"]
    db_user = parsed_yaml_file["db_user"]
    db_password = parsed_yaml_file["db_password"]
    db_host = parsed_yaml_file["db_host"]
    db_port = parsed_yaml_file["db_port"]

print("Settings loaded!")
# %%

subprocess.run(
    f"""ogr2ogr -f PostgreSQL "PG:user={db_user} password={db_password} dbname={db_name}" {geodk_fp}""",
    shell=True,
    check=True,
)

connection = dbf.connect_pg(db_name, db_user, db_password, db_port=db_port)

dbf.run_query_pg("sql/01b_process_geodk.sql", connection)

q = "SELECT objectid, vejkategori FROM geodk_bike LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)

connection.close()

# %%
