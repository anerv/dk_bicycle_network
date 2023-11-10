import geopandas as gpd
import pandas as pd
from shapely.geometry import Polygon, mapping
import h3


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
    hex_pd = pd.DataFrame(hex_list, columns=[f"hex_id_{hex_resolution}"])

    # Create hexagon geometry and GeoDataFrame
    hex_pd["geometry"] = [
        Polygon(h3.h3_to_geo_boundary(x, geo_json=True))
        for x in hex_pd[f"hex_id_{hex_resolution}"]
    ]

    grid = gpd.GeoDataFrame(hex_pd)

    grid.set_crs("4326", inplace=True).to_crs(crs, inplace=True)

    return grid
