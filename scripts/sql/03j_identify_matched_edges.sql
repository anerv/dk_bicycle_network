-- MARK ORG OSM EDGES AS MATCHED
-- TODO: close gaps
ALTER TABLE
    osm_road_edges
ADD
    COLUMN matched BOOLEAN DEFAULT NULL,
ADD
    COLUMN geodk_surface VARCHAR,
ADD
    COLUMN geodk_category VARCHAR;

UPDATE
    osm_road_edges
SET
    matched = TRUE,
    geodk_surface = g.surface,
    geodk_category = g.road
FROM
    matching_geodk_osm._grouped_osm g
WHERE
    matched_final = TRUE
    AND id_osm = g.id_osm;