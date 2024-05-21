-- Drop existing table if any
DROP TABLE IF EXISTS nodes;

-- Rename and update table and columns
ALTER TABLE
    osm_road_edges_vertices_pgr RENAME TO nodes;

ALTER TABLE
    nodes RENAME COLUMN the_geom TO geometry;

-- Add column for OSM ID
ALTER TABLE
    nodes
ADD
    COLUMN osm_id BIGINT DEFAULT NULL;

-- Transfer OSM ID to vertices
WITH updated_osm_ids AS (
    SELECT
        n.id,
        COALESCE(r1.osm_target_id, r2.osm_source_id) AS new_osm_id
    FROM
        nodes n
        JOIN osm_road_edges r1 ON n.id = r1.target
        LEFT JOIN osm_road_edges r2 ON n.id = r2.source
    WHERE
        n.osm_id IS NULL
)
UPDATE
    nodes n
SET
    osm_id = u.new_osm_id
FROM
    updated_osm_ids u
WHERE
    n.id = u.id;

-- Classify nodes based on intersection tags
CREATE TEMP TABLE intersection_tags AS
SELECT
    *,
    NULL :: VARCHAR AS inter_type
FROM
    planet_osm_point
WHERE
    highway = 'traffic_signals'
    OR crossing IN (
        'uncontrolled',
        'unmarked',
        'zebra',
        'marked',
        'controlled',
        'traffic_signals',
        'island'
    )
    OR "crossing:island" = 'yes';

UPDATE
    intersection_tags
SET
    inter_type = CASE
        WHEN (
            highway IS DISTINCT
            FROM
                'traffic_signals'
                AND (
                    crossing IS NULL
                    OR crossing IN ('uncontrolled', 'unmarked')
                )
        )
        OR (
            highway IS DISTINCT
            FROM
                'traffic_signals'
                AND crossing NOT IN (
                    'zebra',
                    'marked',
                    'controlled',
                    'traffic_signals'
                )
        ) THEN 'unregulated'
        WHEN crossing IN ('marked', 'zebra', 'island')
        OR "crossing:island" = 'yes' THEN 'marked'
        WHEN crossing = 'traffic_signals'
        OR highway = 'traffic_signals' THEN 'regulated'
        ELSE inter_type
    END;

-- Transfer intersection tags to nodes
ALTER TABLE
    nodes
ADD
    COLUMN intersection_type VARCHAR DEFAULT NULL,
ADD
    COLUMN highway VARCHAR DEFAULT NULL,
ADD
    COLUMN crossing VARCHAR DEFAULT NULL;

UPDATE
    nodes n
SET
    intersection_type = it.inter_type,
    highway = it.highway,
    crossing = it.crossing
FROM
    intersection_tags it
WHERE
    n.osm_id = it.osm_id;

-- Compute node degrees
CREATE TEMP TABLE node_degrees AS WITH all_node_occurrences AS (
    SELECT
        source AS node
    FROM
        osm_road_edges
    UNION
    ALL
    SELECT
        target AS node
    FROM
        osm_road_edges
)
SELECT
    node,
    COUNT(*) AS C
FROM
    all_node_occurrences
GROUP BY
    node;

ALTER TABLE
    nodes
ADD
    COLUMN node_degree INT DEFAULT NULL;

UPDATE
    nodes n
SET
    node_degree = d.c
FROM
    node_degrees d
WHERE
    n.id = d.node;

-- Drop temporary tables
DROP TABLE IF EXISTS node_degrees,
intersection_tags;