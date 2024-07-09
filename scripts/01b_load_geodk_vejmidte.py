# *** Loading GeoDK data to PostGIS db ***

# %%
import yaml
import subprocess
from src import db_functions as dbf

with open(r"../config.yml") as file:
    parsed_yaml_file = yaml.load(file, Loader=yaml.FullLoader)

    geodk_fp = parsed_yaml_file["geodk_fp"]

    crs = parsed_yaml_file["CRS"]

    db_name = parsed_yaml_file["db_name"]
    db_user = parsed_yaml_file["db_user"]
    db_password = parsed_yaml_file["db_password"]
    db_host = parsed_yaml_file["db_host"]
    db_port = parsed_yaml_file["db_port"]

    geodk_hist = parsed_yaml_file["geodk_hist"]


print("Settings loaded!")

connection = dbf.connect_pg(db_name, db_user, db_password, db_port=db_port)

result = dbf.run_query_pg("DROP TABLE IF EXISTS vejmidte CASCADE;", connection)
if result == "error":
    print("Please fix error before rerunning and reconnect to the database")


subprocess.run(
    f"""ogr2ogr -f PostgreSQL "PG:user={db_user} password={db_password} dbname={db_name}" {geodk_fp} -nln vejmidte""",
    shell=True,
    check=True,
)

# Dropping historical records
if geodk_hist is True:

    q = "DELETE FROM vejmidte WHERE registreringtil IS NOT NULL OR virkningtil IS NOT NULL;"

    result = dbf.run_query_pg(q, connection)
    if result == "error":
        print("Please fix error before rerunning and reconnect to the database")

    print("Dropped historical records!")

result = dbf.run_query_pg("sql/01b_process_geodk.sql", connection)
if result == "error":
    print("Please fix error before rerunning and reconnect to the database")

q = "SELECT objectid, vejkategori FROM geodk_bike LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)

connection.close()

print("Script 01b complete!")
# %%
