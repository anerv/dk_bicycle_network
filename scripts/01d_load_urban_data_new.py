# %%
# *** URBAN/RURAL DATA ***

### Codes:
# rural = [11,12]
# semi_rural = [13]
# sub_semi_urban = [21,22]
# urban = [23,30]

### ALTERNATIVE APPROACH
# Make hex grid covering DK
# For each grid cell, get centroid
# Sample raster value of centroid

import rasterio
import geopandas as gpd
import pandas as pd
import yaml
import json

from src import db_functions as dbf
from rasterio.merge import merge
from rasterio.mask import mask
from rasterio.warp import calculate_default_transform, reproject, Resampling

import rioxarray as rxr
import h3
from shapely.geometry import Polygon, mapping

# %%
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


def create_h3_grid(polygon_gdf, hex_resolution, crs, buffer_dist):
    # Inspired by https://stackoverflow.com/questions/51159241/how-to-generate-shapefiles-for-h3-hexagons-in-a-particular-area

    print(f"Creating hexagons at resolution {hex_resolution}...")

    union_poly = (
        polygon_gdf.buffer(buffer_dist).to_crs("EPSG:4326").geometry.unary_union
    )

    # Find the hexagons within the shape boundary using PolyFill
    hex_list = []
    for n, g in enumerate(union_poly.geoms):
        temp = mapping(g)
        temp["coordinates"] = [[[j[1], j[0]] for j in i] for i in temp["coordinates"]]
        hex_list.extend(h3.polyfill(temp, res=hex_resolution))

    # Create hexagon data frame
    hex_pd = pd.DataFrame(hex_list, columns=["hex_id"])

    # Create hexagon geometry and GeoDataFrame
    hex_pd["geometry"] = [
        Polygon(h3.h3_to_geo_boundary(x, geo_json=True)) for x in hex_pd["hex_id"]
    ]

    grid = gpd.GeoDataFrame(hex_pd)

    grid.set_crs("4326", inplace=True).to_crs(crs, inplace=True)

    grid["grid_id"] = grid.hex_id

    return grid


h3_grid = create_h3_grid(dissolved, h3_urban_level, crs, buffer_dist)

# Get h3 points for all rows in h3 grid
h3_grid["lat"] = h3_grid["hex_id"].apply(lambda x: h3.h3_to_geo(x)[0])
h3_grid["lng"] = h3_grid["hex_id"].apply(lambda x: h3.h3_to_geo(x)[1])

h3_points = h3_grid[["hex_id", "lat", "lng"]]

h3_points_gdf = gpd.GeoDataFrame(
    h3_points, geometry=gpd.points_from_xy(h3_points.lng, h3_points.lat)
)
# %%
# point_coords = [(x, y) for x, y in zip(h3_points_gdf.lng, h3_points_gdf.lat)]

# src = rasterio.open(proj_fp_wgs84)

# h3_points_gdf["urban_code"] = [x[0] for x in src.sample(point_coords)]

# %%
h3_points_fp = f"../data/processed/h3_points_{h3_urban_level}.gpkg"
h3_points_gdf.to_file(h3_points_fp)

from qgis import processing
from qgis.core import QgsVectorLayer, QgsRasterLayer

point_layer = QgsVectorLayer(h3_points_fp, "H3 points", "ogr")
urban_raster = QgsRasterLayer(proj_fp_wgs84, "urban raster")

urban_sample_values_fp = "../data/processed/h3_points_{h3_urban_level}_urban_codes.gpkg"

elevation_values = processing.run(
    "native:rastersampling",
    {
        "INPUT": point_layer,
        "RASTERCOPY": urban_raster,
        "COLUMN_PREFIX": "urban_",
        "OUTPUT": urban_sample_values_fp,
    },
)

urban_samples_gdf = gpd.read_file(urban_sample_values_fp)

# TODO: join with hexagons
h3_grid.merge(
    urban_samples_gdf[["hex_id", "urban_code"]], left_on="hex_id", right_on="hex_id"
)
# %%
# *** CONVERT TO H3 HEXAGONS ***
# CONVERT TO POINT GEOMETRIES

urban_df = (
    rxr.open_rasterio(proj_fp_wgs84)
    .sel(band=1)
    .to_pandas()
    .stack()
    .reset_index()
    .rename(columns={"x": "lng", "y": "lat", 0: "urban_code"})
)

urban_df = urban_df[urban_df.urban_code > -200]
urban_df = urban_df[urban_df.urban_code != 10]

urban_gdf = gpd.GeoDataFrame(
    urban_df, geometry=gpd.points_from_xy(urban_df.lng, urban_df.lat)
)

urban_gdf.set_crs("EPSG:4326", inplace=True)

dk_gdf = gpd.GeoDataFrame({"geometry": dissolved_proj}, crs=dissolved_proj.crs)
dk_gdf.to_crs("EPSG:4326", inplace=True)

urban_gdf = gpd.sjoin(urban_gdf, dk_gdf, predicate="within", how="inner")
urban_gdf.drop("index_right", axis=1, inplace=True)

# %%
# INDEX URBAN DATA WITH H3

col_hex_id = f"hex_id_{h3_urban_level}"
col_geom = f"hex_geometry_{h3_urban_level}"

urban_gdf[col_hex_id] = urban_gdf.apply(
    lambda row: h3.geo_to_h3(lat=row["lat"], lng=row["lng"], resolution=h3_urban_level),
    axis=1,
)

# Method for choosing the most occuring value in hex grid cell
grouped = urban_gdf.groupby(col_hex_id)

hex_urban_code = {}

for name, g in grouped:
    hex_urban_code[name] = g.urban_code.value_counts().idxmax()

h3_groups = pd.DataFrame.from_dict(
    hex_urban_code, orient="index", columns=["urban_code"]
).reset_index()

h3_groups.rename({"index": col_hex_id}, axis=1, inplace=True)

h3_groups["hex_geometry"] = h3_groups[col_hex_id].apply(
    lambda x: {
        "type": "Polygon",
        "coordinates": [h3.h3_to_geo_boundary(h=x, geo_json=True)],
    }
)

# Create polygon geometries
h3_groups["geometry"] = h3_groups["hex_geometry"].apply(
    lambda x: Polygon(list(x["coordinates"][0]))
)

h3_gdf = gpd.GeoDataFrame(h3_groups, geometry="geometry", crs="EPSG:4326")

h3_gdf.to_crs(crs, inplace=True)


# Export data
print("Saving data to Postgres!")

connection = dbf.connect_pg(db_name, db_user, db_password, db_port)

engine = dbf.connect_alc(db_name, db_user, db_password, db_port=db_port)

table_name = f"urban_polygons_{h3_urban_level}"
dbf.to_postgis(geodataframe=h3_gdf, table_name=table_name, engine=engine)

q = f"SELECT hex_id_{h3_urban_level}, urban_code FROM urban_polygons_{h3_urban_level} LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)

connection.close()


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
