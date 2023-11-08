# *** Loading GeoDK data to PostGIS db ***

# %%
import geopandas as gpd
import yaml
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
# NOTE: This can take a while!
geodk = gpd.read_file(geodk_fp)

# %%
geodk.columns = geodk.columns.str.lower()

# Get cycling infrastructure
geodk_bike = geodk.loc[
    geodk.vejkategori.isin(["Cykelsti langs vej", "Cykelbane langs vej"])
]

if geodk_bike.crs != crs:
    geodk_bike = geodk_bike.to_crs(crs)

assert geodk_bike.crs == crs

assert len(geodk_bike) == len(geodk_bike[geodk_id_col].unique())

useful_cols = [
    "objectid",
    "status",
    "geometry",
    "kommunekode",
    "trafikart",
    "niveau",
    "overflade",
    "vejmidtetype",
    "vejkategori",
]

geodk_bike = geodk_bike[useful_cols]

# %%
connection = dbf.connect_pg(db_name, db_user, db_password, db_port=db_port)

engine = dbf.connect_alc(db_name, db_user, db_password, db_port=db_port)

dbf.to_postgis(geodataframe=geodk_bike, table_name="geodk_bike", engine=engine)

q = "SELECT objectid, vejkategori FROM geodk_bike LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)

connection.close()

# %%
