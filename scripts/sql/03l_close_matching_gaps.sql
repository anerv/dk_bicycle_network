-- MARK edges as matched if short and between matched edges
-- NODES OF MATCHED EDGES
CREATE VIEW matching_geodk_osm._matched_nodes AS (
    SELECT
        source AS node
    FROM
        osm_road_edges
    WHERE
        matched = TRUE
    UNION
    SELECT
        target AS node
    FROM
        osm_road_edges
    WHERE
        matched = TRUE
);

CREATE TABLE matching_geodk_osm._potential_gaps AS (
    SELECT
        *
    FROM
        osm_road_edges
    WHERE
        source IN (
            SELECT
                node
            FROM
                matching_geodk_osm._matched_nodes
        )
        AND target IN (
            SELECT
                node
            FROM
                matching_geodk_osm._matched_nodes
        )
        AND (
            bicycle <> 'no'
            OR bicycle IS NULL
        )
        AND (
            matched IS NULL
            OR matched IS FALSE
        )
        AND ST_length(geometry) <= 20
        AND highway NOT IN (
            'footway',
            'bridleway',
            'unclassified',
            'pedestrian',
            'motorway',
            'motorway_link'
        )
);

UPDATE
    osm_road_edges
SET
    matched = TRUE
WHERE
    id IN (
        SELECT
            id
        FROM
            matching_geodk_osm._potential_gaps
    );