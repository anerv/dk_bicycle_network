ALTER TABLE
    osm_road_edges_vertices_pgr RENAME TO nodes;

ALTER TABLE
    nodes RENAME COLUMN the_geom TO geometry;

-- TRANSFER OSM ID TO VERTICES
ALTER TABLE
    nodes
ADD
    COLUMN osm_id BIGINT DEFAULT NULL;

UPDATE
    nodes
SET
    osm_id = r.osm_target_id
FROM
    osm_road_edges r
WHERE
    nodes.id = r.target;

UPDATE
    nodes i
SET
    osm_id = r.osm_source_id
FROM
    osm_road_edges r
WHERE
    i.id = r.source
    AND i.osm_id IS NULL;

-- Classify nodes
CREATE TABLE intersection_tags AS
SELECT
    *
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

ALTER TABLE
    intersection_tags
ADD
    COLUMN inter_type VARCHAR DEFAULT NULL;

UPDATE
    intersection_tags
SET
    inter_type = 'unregulated'
WHERE
    (
        highway NOT IN ('traffic_signals')
        OR highway IS NULL
    )
    AND (
        crossing IN ('uncontrolled', 'unmarked')
        OR crossing IS NULL
    )
    OR (
        highway NOT IN ('traffic_signals')
        OR highway IS NULL
    )
    AND (
        crossing NOT IN (
            'zebra',
            'marked',
            'controlled',
            'traffic_signals'
        )
        OR crossing IS NULL
    );

UPDATE
    intersection_tags
SET
    inter_type = 'marked'
WHERE
    crossing IN ('marked', 'zebra', 'island')
    OR 'crossing:island' IN ('yes');

--OR flashing_lights IN ('yes','sensor','button','always');
UPDATE
    intersection_tags
SET
    inter_type = 'regulated'
WHERE
    crossing = 'traffic_signals'
    OR highway = 'traffic_signals';

-- Transfer to nodes
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

-- what to do with marked crossings that do not fall on nodes?