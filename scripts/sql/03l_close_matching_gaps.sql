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

-- -- Remove short disconnected matched edges
CREATE TABLE matching_geodk_osm._node_matched_edges AS WITH all_matched_node_occurences AS (
    SELECT
        source AS node,
        id
    FROM
        osm_road_edges
    WHERE
        matched IS TRUE
    UNION
    SELECT
        target AS node,
        id
    FROM
        osm_road_edges
    WHERE
        matched IS TRUE
)
SELECT
    node,
    COUNT(*) AS C
FROM
    all_matched_node_occurences
GROUP BY
    node
ORDER BY
    C DESC;

CREATE TABLE matching_geodk_osm._potential_floating_edges AS WITH isolated_matched_nodes AS (
    SELECT
        node
    FROM
        matching_geodk_osm._node_matched_edges
    WHERE
        C = 1
)
SELECT
    *
FROM
    osm_road_edges
WHERE
    matched IS TRUE
    AND ST_length(geometry) < 10
    AND source IN (
        SELECT
            node
        FROM
            isolated_matched_nodes
    )
    AND target IN (
        SELECT
            node
        FROM
            isolated_matched_nodes
    );

UPDATE
    osm_road_edges
SET
    matched = FALSE,
    geodk_category = NULL,
    geodk_surface = NULL
WHERE
    id IN (
        SELECT
            id
        FROM
            matching_geodk_osm._potential_floating_edges
    );

-- DROP TABLE IF EXISTS matching_geodk_osm._potential_floating_edges;
-- DROP TABLE IF EXISTS matching_geodk_osm._node_matched_edges;
-- DROP VIEW IF EXISTS matching_geodk_osm._matched_nodes;