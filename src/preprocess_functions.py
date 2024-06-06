import geopandas as gpd
import pandas as pd
from shapely.geometry import Polygon, mapping, MultiLineString
from shapely.ops import linemerge


def standardize_matched_segments(nested_list):
    """
    Function for processing a list of list with identical values of either True and False (e.g. [[F],[T,T,T,T,T],[F,F]).
    Assumes that adjacent lists with identical values have been merged.
    Removes nested lists of length 1 by converting to the opposite value and merging with adjacent list.
    """
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
    """
    Function for processing a list of list with identical values (e.g. [[T,T],[T,T,T],[F,F]).
    Adjacent lists with identical values are merged.
    """
    # Assumes nested lists with identical values
    i = 0
    while i < len(nested_list) - 1:
        # for i in range(len(nested_list) - 1):
        if nested_list[i][0] == nested_list[i + 1][0]:
            nested_list[i + 1] = nested_list[i] + nested_list[i + 1]
            nested_list.pop(i)

        i += 1

    return nested_list


def split_edges(edges_to_split, segment_gdf):
    """
    Takes a geodataframe (edges_to_split) with partially matched edges,
    based on their matched and unmatched segments (segments_gdf),
    and converts each edge into a matched and unmatched geometry.
    Returns a new geodataframe with split edges and associated edge ids.
    """
    segment_ids = []
    id_osm = []
    geometries = []
    matched = []

    for _, data in edges_to_split.iterrows():
        matched_list = data["group_matching"]
        segment_id_list = data["ids"]

        matched_list_new = matched_list[0]

        matched_list_new.extend(matched_list[1])
        matched_segment_ids = [
            x for x, y in zip(segment_id_list, matched_list_new) if y == True
        ]
        unmatched_segment_ids = [
            x for x, y in zip(segment_id_list, matched_list_new) if y == False
        ]

        matched_segments = segment_gdf.loc[segment_gdf.id.isin(matched_segment_ids)]

        unmatched_segments = segment_gdf.loc[segment_gdf.id.isin(unmatched_segment_ids)]

        matched_geom = linemerge(MultiLineString(matched_segments.geometry.to_list()))

        unmatched_geom = linemerge(
            MultiLineString(unmatched_segments.geometry.to_list())
        )

        segment_ids.append(matched_segment_ids)
        segment_ids.append(unmatched_segment_ids)
        id_osm.extend([data["id_osm"], data["id_osm"]])
        geometries.append(matched_geom)
        geometries.append(unmatched_geom)
        matched.extend([True, False])

    dict = {
        "segment_ids": segment_ids,
        "id_osm": id_osm,
        "matched": matched,
        "geometry": geometries,
    }

    new_edges = gpd.GeoDataFrame(dict, crs="EPSG:25832")

    assert len(new_edges) == 2 * len(edges_to_split)

    assert new_edges.geometry.length.sum() <= segment_gdf.geometry.length.sum()

    assert new_edges.loc[0, "id_osm"] == new_edges.loc[1, "id_osm"]

    assert new_edges.loc[0, "matched"] == True
    assert new_edges.loc[1, "matched"] == False

    return new_edges
