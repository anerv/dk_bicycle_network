# *** CREATE POPULATION H3 HEX GRID ***

# %%
import h3
import rasterio
import geopandas as gpd

import yaml
import matplotlib.pyplot as plt
import json

from rasterio.merge import merge
from rasterio.mask import mask
from rasterio.warp import calculate_default_transform, reproject, Resampling
import rioxarray as rxr
from shapely.geometry import Polygon
from src import db_functions as dbf

with open(r"../config.yml") as file:
    parsed_yaml_file = yaml.load(file, Loader=yaml.FullLoader)

    crs = parsed_yaml_file["CRS"]

    pop_fp_1 = parsed_yaml_file["pop_fp_1"]
    pop_fp_2 = parsed_yaml_file["pop_fp_2"]

    db_name = parsed_yaml_file["db_name"]
    db_user = parsed_yaml_file["db_user"]
    db_password = parsed_yaml_file["db_password"]
    db_host = parsed_yaml_file["db_host"]
    db_port = parsed_yaml_file["db_port"]

    h3_pop_level = parsed_yaml_file["h3_pop_level"]

print("Settings loaded!")
# %%

# ** PROCESS INPUT RASTERS ***
# LOAD DATA
pop_src_1 = rasterio.open(pop_fp_1)
pop_src_2 = rasterio.open(pop_fp_2)

# MERGE RASTERS
mosaic, out_trans = merge([pop_src_1, pop_src_2])

out_meta = pop_src_1.meta.copy()

out_meta.update(
    {
        "driver": "GTiff",
        "height": mosaic.shape[1],
        "width": mosaic.shape[2],
        "transform": out_trans,
        "crs": pop_src_1.crs,
    }
)
merged_fp = "../data/processed/pop/merged_pop_raster.tif"
with rasterio.open(merged_fp, "w", **out_meta) as dest:
    dest.write(mosaic)

merged = rasterio.open(merged_fp)

# Load DK boundaries
engine = dbf.connect_alc(db_name, db_user, db_password, db_port=db_port)

get_muni = "SELECT navn, kommunekode, geometry FROM muni_boundaries"

muni = gpd.GeoDataFrame.from_postgis(get_muni, engine, geom_col="geometry")

dissolved = muni.dissolve()
dissolved_buffer = dissolved.buffer(500)

dissolved_proj = dissolved_buffer.to_crs(merged.crs)
convex = dissolved_proj.convex_hull

geo = gpd.GeoDataFrame({"geometry": convex[0]}, index=[0], crs=merged.crs)

coords = [json.loads(geo.to_json())["features"][0]["geometry"]]

# Clip raster to DK extent
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
clipped_fp = "../data/processed/pop/clipped_pop_raster.tif"
with rasterio.open(clipped_fp, "w", **out_meta) as dest:
    dest.write(clipped)

# REPROJECT TO CRS USED BY H3
dst_crs = "EPSG:4326"
proj_fp_wgs84 = "../data/processed/pop/reproj_pop_raster_wgs84.tif"

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
                resampling=Resampling.bilinear,
            )


test = rasterio.open(proj_fp_wgs84)
assert test.crs.to_string() == "EPSG:4326"

print("Population data has been merged, clipped, and reprojected!")

# %%
# *** CONVERT TO H3 HEXAGONS ***

# convert to point geometries
pop_df = (
    rxr.open_rasterio(proj_fp_wgs84)
    .sel(band=1)
    .to_pandas()
    .stack()
    .reset_index()
    .rename(columns={"x": "lng", "y": "lat", 0: "population"})
)

# Ignore no data values
# pop_df = pop_df[pop_df.population > -200]

pop_gdf = gpd.GeoDataFrame(pop_df, geometry=gpd.points_from_xy(pop_df.lng, pop_df.lat))

pop_gdf.set_crs("EPSG:4326", inplace=True)

# join with DK bounday
dk_gdf = gpd.GeoDataFrame({"geometry": dissolved_proj}, crs=dissolved_proj.crs)
dk_gdf.to_crs("EPSG:4326", inplace=True)

pop_gdf = gpd.sjoin(pop_gdf, dk_gdf, predicate="within", how="inner")

pop_gdf.drop("index_right", axis=1, inplace=True)

# INDEX POP DATA WITH H3
col_hex_id = f"hex_id_{h3_pop_level}"
col_geom = f"hex_geometry_{h3_pop_level}"

pop_gdf[col_hex_id] = pop_gdf.apply(
    lambda row: h3.geo_to_h3(lat=row["lat"], lng=row["lng"], resolution=h3_pop_level),
    axis=1,
)

# Convert to H3 polygons
h3_groups = (
    pop_gdf.groupby(col_hex_id)["population"].sum().to_frame("population").reset_index()
)

h3_groups[f"hex_geometry_{h3_pop_level}"] = h3_groups[col_hex_id].apply(
    lambda x: {
        "type": "Polygon",
        "coordinates": [h3.h3_to_geo_boundary(h=x, geo_json=True)],
    }
)
h3_groups["geometry"] = h3_groups[col_geom].apply(
    lambda x: Polygon(list(x["coordinates"][0]))
)

h3_gdf = gpd.GeoDataFrame(h3_groups, geometry="geometry", crs="EPSG:4326")

h3_gdf.to_crs(crs, inplace=True)

# %%
# *** EXPORT DATA ***
connection = dbf.connect_pg(db_name, db_user, db_password, db_port=db_port)

engine = dbf.connect_alc(db_name, db_user, db_password, db_port=db_port)

table_name = f"pop_polygons_{h3_pop_level}"
dbf.to_postgis(geodataframe=h3_gdf, table_name=table_name, engine=engine)

q = f"SELECT {col_hex_id}, population FROM pop_polygons_{h3_pop_level} LIMIT 10;"

test = dbf.run_query_pg(q, connection)

print(test)

connection.close()

print("Data saved to Postgres DB!")

# %%
