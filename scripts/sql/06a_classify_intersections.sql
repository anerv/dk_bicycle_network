SELECT
    pgr_createverticestable('osm_road_edges', 'geometry', 'source', 'target');

ALTER TABLE
    osm_road_edges_vertices_pgr RENAME TO intersections;

-- TODO: CREATE SPATIAL INDEX
-- TRANSFER OSM ID TO VERTICES
ALTER TABLE
    intersections
ADD
    COLUMN osm_id BIGINT DEFAULT NULL;

UPDATE
    intersections
SET
    osm_id = r.osm_target_id
FROM
    osm_road_edges r
WHERE
    intersections.id = r.target;

UPDATE
    intersections i
SET
    osm_id = r.osm_source_id
FROM
    osm_road_edges r
WHERE
    i.id = r.source
    AND i.osm_id IS NULL;

-- CLASSIFY OSM POINTS
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

ALTER TABLE
    intersections
ADD
    COLUMN inter_type VARCHAR DEFAULT NULL;

UPDATE
    intersections i
SET
    inter_type = it.inter_type
FROM
    intersection_tags it
WHERE
    i.osmid = it.id;

CREATE MATERIALIZED VIEW unmatched_inter_tags AS
SELECT
    *
FROM
    intersection_tags it
WHERE
    NOT EXISTS (
        SELECT
        FROM
            intersections i
        WHERE
            i.osmid = it.id
    );