# *** URBAN/RURAL DATA ***

### Codes:
# rural = [11,12]
# semi_rural = [13]
# sub_semi_urban = [21,22]
# urban = [23,30]

# %%
import geopandas as gpd
import pandas as pd
import yaml
import json
import rasterio
from rasterio.merge import merge
from rasterio.mask import mask
from rasterio.warp import calculate_default_transform, reproject, Resampling
import rioxarray as rxr
import h3
from shapely.geometry import Polygon

from src import db_functions as dbf
from src import preprocess_functions as prep

with open(r"../config.yml") as file:
    parsed_yaml_file = yaml.load(file, Loader=yaml.FullLoader)

    crs = parsed_yaml_file["CRS"]

    urban_fp_1 = parsed_yaml_file["urban_fp_1"]
    urban_fp_2 = parsed_yaml_file["urban_fp_2"]

    db_name = parsed_yaml_file["db_name"]
    db_user = parsed_yaml_file["db_user"]
    db_password = parsed_yaml_file["db_password"]
    db_host = parsed_yaml_file["db_host"]
    db_port = parsed_yaml_file["db_port"]

    h3_urban_level = parsed_yaml_file["h3_urban_level"]


print("Settings loaded!")

# %%
# *** PROCESS INPUT RASTERS ***

# LOAD DATA
urban_src_1 = rasterio.open(urban_fp_1)
urban_src_2 = rasterio.open(urban_fp_2)

# MERGE RASTERS
mosaic, out_trans = merge([urban_src_1, urban_src_2])

out_meta = urban_src_1.meta.copy()

out_meta.update(
    {
        "driver": "GTiff",
        "height": mosaic.shape[1],
        "width": mosaic.shape[2],
        "transform": out_trans,
        "crs": urban_src_1.crs,
    }
)
merged_fp = "../data/processed/urban/merged_urban_raster.tif"
with rasterio.open(merged_fp, "w", **out_meta) as dest:
    dest.write(mosaic)

merged = rasterio.open(merged_fp)

# Load DK boundaries
engine = dbf.connect_alc(db_name, db_user, db_password, db_port=db_port)

get_muni = "SELECT navn, kommunekode, geometry FROM muni_boundaries"

muni = gpd.GeoDataFrame.from_postgis(get_muni, engine, geom_col="geometry")

dissolved = muni.dissolve()
buffer_dist = 500
dissolved_buffer = dissolved.buffer(buffer_dist)

dissolved_proj = dissolved_buffer.to_crs(merged.crs)
convex = dissolved_proj.convex_hull


geo = gpd.GeoDataFrame({"geometry": convex[0]}, index=[0], crs=merged.crs)

coords = [json.loads(geo.to_json())["features"][0]["geometry"]]

clipped, out_transform = mask(merged, shapes=coords, crop=True)

out_meta = merged.meta.copy()

out_meta.update(
    {
        "driver": "GTiff",
        "height": clipped.shape[1],
        "width": clipped.shape[2],
        "transform": out_transform,
        "crs": merged.crs,
    }
)
clipped_fp = "../data/processed/urban/clipped_urban_raster.tif"
with rasterio.open(clipped_fp, "w", **out_meta) as dest:
    dest.write(clipped)


# REPROJECT TO CRS USED BY H3
dst_crs = "EPSG:4326"
proj_fp_wgs84 = "../data/processed/urban/reproj_urban_raster_wgs84.tif"

with rasterio.open(clipped_fp) as src:
    transform, width, height = calculate_default_transform(
        src.crs, dst_crs, src.width, src.height, *src.bounds
    )
    kwargs = src.meta.copy()
    kwargs.update(
        {"crs": dst_crs, "transform": transform, "width": width, "height": height}
    )

    with rasterio.open(proj_fp_wgs84, "w", **kwargs) as dst:
        for i in range(1, src.count + 1):
            reproject(
                source=rasterio.band(src, i),
                destination=rasterio.band(dst, i),
                src_transform=src.transform,
                src_crs=src.crs,
                dst_transform=transform,
                dst_crs=dst_crs,
                resampling=Resampling.mode,
            )  # Using the most often appearing value


test = rasterio.open(proj_fp_wgs84)
assert test.crs.to_string() == "EPSG:4326"

print("urban data has been merged, clipped,and reprojected!")

# %%
# *** CONVERT TO H3 HEXAGONS ***

# Create h3 grid for entire study area
h3_grid = prep.create_h3_grid(dissolved, h3_urban_level, crs, buffer_dist)

hex_id_col = f"hex_id_{h3_urban_level}"
# Get h3 points for all rows in h3 grid
h3_grid["lat"] = h3_grid[hex_id_col].apply(lambda x: h3.h3_to_geo(x)[0])
h3_grid["lng"] = h3_grid[hex_id_col].apply(lambda x: h3.h3_to_geo(x)[1])

# create point gdf
h3_points = h3_grid[[f"hex_id_{h3_urban_level}", "lat", "lng"]]

h3_points_gdf = gpd.GeoDataFrame(
    h3_points, geometry=gpd.points_from_xy(h3_points.lng, h3_points.lat)
)

# sample raster
point_coords = [(x, y) for x, y in zip(h3_points_gdf.lng, h3_points_gdf.lat)]

src = rasterio.open(proj_fp_wgs84)

h3_points_gdf["urban_code"] = [x[0] for x in src.sample(point_coords)]

h3_grid = h3_grid.merge(
    h3_points_gdf[[hex_id_col, "urban_code"]], left_on=hex_id_col, right_on=hex_id_col
)

h3_grid.to_crs(crs, inplace=True)
assert h3_grid.crs == crs


# %%
# Export data
print("Saving data to Postgres!")

connection = dbf.connect_pg(db_name, db_user, db_password, db_port)

engine = dbf.connect_alc(db_name, db_user, db_password, db_port=db_port)

table_name = f"urban_polygons_{h3_urban_level}"
dbf.to_postgis(geodataframe=h3_grid, table_name=table_name, engine=engine)

q = f"SELECT {hex_id_col}, urban_code FROM urban_polygons_{h3_urban_level} LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)

connection.close()

# %%
print("Classifying urban polygons!")

connection = dbf.connect_pg(db_name, db_user, db_password, db_port)

engine = dbf.connect_alc(db_name, db_user, db_password, db_port)

classify_polys = [
    f"ALTER TABLE urban_polygons_{h3_urban_level} ADD COLUMN urban VARCHAR DEFAULT NULL;",
    f"UPDATE urban_polygons_{h3_urban_level} SET urban = 'rural' WHERE urban_code IN (11,12);"
    f"UPDATE urban_polygons_{h3_urban_level} SET urban = 'semi-rural' WHERE urban_code = 13;"
    f"UPDATE urban_polygons_{h3_urban_level} SET urban = 'sub-semi-urban' WHERE urban_code IN (21,22);"
    f"UPDATE urban_polygons_{h3_urban_level} SET urban = 'urban' WHERE urban_code IN (23,30);",
]

for c in classify_polys:
    classify = dbf.run_query_pg(c, connection)


q = f"SELECT hex_id_{h3_urban_level}, urban_code, urban FROM urban_polygons_{h3_urban_level} LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)

connection.close()

# %%
