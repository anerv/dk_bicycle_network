-- Get info on attributes for matched edge segments
ALTER TABLE
    matching_geodk_osm._decided_segments
ADD
    COLUMN geodk_surface VARCHAR,
ADD
    COLUMN geodk_category VARCHAR;

UPDATE
    matching_geodk_osm._decided_segments d
SET
    geodk_surface = g.surface,
    geodk_category = g.road
FROM
    matching_geodk_osm._grouped_osm g
WHERE
    d.matched = TRUE
    and d.id_osm = g.id_osm;

-- save org edges which will be split
CREATE TABLE matching_geodk_osm._org_split_edges AS (
    SELECT
        *
    FROM
        osm_road_edges
    WHERE
        id IN (
            SELECT
                id_osm
            FROM
                matching_geodk_osm._decided_segments
        )
);

CREATE TABLE matching_geodk_osm._org_split_edges_copy AS (
    SELECT
        *
    FROM
        osm_road_edges
    WHERE
        id IN (
            SELECT
                id_osm
            FROM
                matching_geodk_osm._decided_segments
        )
);

ALTER TABLE
    matching_geodk_osm._org_split_edges DROP COLUMN geometry;

CREATE TABLE matching_geodk_osm._joined_decided_segments AS (
    SELECT
        *
    FROM
        matching_geodk_osm._org_split_edges o
        JOIN matching_geodk_osm._decided_segments d ON id = d.id_osm
);

ALTER TABLE
    matching_geodk_osm._joined_decided_segments DROP COLUMN id_osm,
    DROP column segment_ids;

DELETE FROM
    osm_road_edges
WHERE
    id IN (
        SELECT
            id
        FROM
            matching_geodk_osm._joined_decided_segments
    );

ALTER TABLE
    osm_road_edges
ADD
    COLUMN matched BOOLEAN DEFAULT NULL,
ADD
    COLUMN geodk_surface VARCHAR,
ADD
    COLUMN geodk_category VARCHAR;

-- INSERT
INSERT INTO
    osm_road_edges
SELECT
    "id",
    "osm_id",
    "osm_source_id",
    "osm_target_id",
    "source",
    "target",
    "km",
    "kmh",
    "cost",
    "reverse_cost",
    "x1",
    "y1",
    "x2",
    "y2",
    "geometry",
    "access",
    "barrier",
    "bicycle",
    "bridge",
    "crossing",
    "cycleway",
    "cycleway:left",
    "cycleway:right",
    "cycleway:both",
    "cycleway:width",
    "cycleway:left:width",
    "cycleway:right:width",
    "cycleway:both:width",
    "cycleway:surface",
    "cyclestreet",
    "bicycle_road",
    "flashing_lights",
    "foot",
    "highway",
    "junction",
    "lanes",
    "lanes:backward",
    "lanes:forward",
    "layer",
    "lit",
    "maxspeed",
    "maxspeed:advisory",
    "motorcar",
    "motor_vehicle",
    "name",
    "oneway",
    "oneway:bicycle",
    "parking",
    "parking:lane",
    "parking:lane:right",
    "parking:lane:left",
    "parking:lane:both",
    "route",
    "segregated",
    "service",
    "separation",
    "sidewalk",
    "source:maxspeed",
    "surface",
    "tracktype",
    "tunnel",
    "width",
    "tags",
    "bicycle_infrastructure",
    "bicycle_protected",
    "matched",
    "geodk_surface",
    "geodk_category"
FROM
    matching_geodk_osm._joined_decided_segments;

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
    AND id = g.id_osm;

-- Clear topology for updated and adjacent edges
WITH updated_nodes AS (
    SELECT
        source
    FROM
        matching_geodk_osm._joined_decided_segments
    UNION
    SELECT
        target
    FROM
        matching_geodk_osm._joined_decided_segments
)
UPDATE
    osm_road_edges
SET
    source = NULL,
    target = NULL,
WHERE
    (
        source IN updated_nodes
        OR target IN updated_nodes
    );

UPDATE
    osm_road_edges
SET
    source = NULL,
    target = NULL,
    x1 = NULL,
    x2 = NULL,
    y1 = NULL,
    y2 = NULL
WHERE
    id IN (
        SELECT
            id_osm
        FROM
            matching_geodk_osm._joined_decided_segments
    );

-- create new unique id
ALTER osm_road_edges
ADD
    COLUMN old_id BIGINT;

UPDATE
    osm_road_edges
SET
    old_id = id;

UPDATE
    osm_road_edges DROP COLUMN id;

ALTER TABLE
    osm_road_edges
ADD
    COLUMN id BIGSERIAL;

-- fill out x1 etc
UPDATE
    osm_road_edges
SET
    x1 = ST_X(ST_StartPoint(geometry)),
    y1 = ST_Y(ST_StartPoint(geometry)),
    x2 = ST_X(ST_EndPoint(geometry)),
    y2 = ST_Y(ST_EndPoint(geometry))
WHERE
    x1 IS NULL;

-- rebuild topology
SELECT
    pgr_createTopology(
        'osm_road_edges',
        0.001,
        'geometry',
        'id',
        'source',
        'target',
        --clean := true
    );

-- OR: clean id source target etc cols for all from joined segments AND FOR all connecting to those
-- TODO: close gaps
-- get rid of null values in arrays
-- update costs?
VACUUM ANALYZE VERBOSE osm_road_edges;