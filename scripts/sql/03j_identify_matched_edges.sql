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

-- INSERT NEW SPLIT EDGES
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

-- MARK EDGES AS MATCHED BASED ON GROUPED OSM SEGMENTS
UPDATE
    osm_road_edges
SET
    matched = TRUE,
    geodk_surface = g.surface,
    geodk_category = g.road
FROM
    matching_geodk_osm._grouped_osm g
WHERE
    g.matched_final = TRUE
    AND id = g.id_osm;

UPDATE
    osm_road_edges
SET
    x1 = NULL,
    x2 = NULL,
    y1 = NULL,
    y2 = NULL
WHERE
    id IN (
        SELECT
            id
        FROM
            matching_geodk_osm._joined_decided_segments
    );

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

-- create new unique id
ALTER TABLE
    osm_road_edges
ADD
    COLUMN old_id BIGINT;

UPDATE
    osm_road_edges
SET
    old_id = id;

ALTER TABLE
    osm_road_edges DROP COLUMN id;

ALTER TABLE
    osm_road_edges
ADD
    COLUMN id BIGSERIAL;

-- rebuild topology
SELECT
    pgr_createTopology(
        'osm_road_edges',
        0.001,
        'geometry',
        'id',
        'source',
        'target',
        clean := true
    );

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

ALTER TABLE
    osm_road_edges
ADD
    COLUMN category_temp VARCHAR,
ADD
    COLUMN surface_temp VARCHAR;

UPDATE
    osm_road_edges
SET
    surface_temp =(
        SELECT
            array(
                SELECT
                    unnest(geodk_surface :: text [ ])
                EXCEPT
                SELECT
                    NULL
            )
    )
WHERE
    matched IS TRUE;

UPDATE
    osm_road_edges
SET
    category_temp =(
        SELECT
            array(
                SELECT
                    unnest(geodk_category :: text [ ])
                EXCEPT
                SELECT
                    NULL
            )
    )
WHERE
    matched IS TRUE;

UPDATE
    osm_road_edges
SET
    category_temp = CASE
        WHEN category_temp = '{"Cykelsti langs vej"}' THEN 'Cykelsti langs vej'
        WHEN category_temp = '{"Cykelbane langs vej"}' THEN 'Cykelbane langs vej'
        WHEN category_temp = '{"Cykelbane langs vej","Cykelsti langs vej"}' THEN 'Cykelsti langs vej'
        WHEN category_temp = '{"Cykelsti langs vej","Cykelbane langs vej"}' THEN 'Cykelsti langs vej'
    END
WHERE
    matched = TRUE;

UPDATE
    osm_road_edges
SET
    surface_temp = CASE
        WHEN surface_temp = '{Befæstet}' THEN 'Befæstet'
        WHEN surface_temp = '{Ubefæstet}' THEN 'Ubefæstet'
        WHEN surface_temp = '{Ukendt}' THEN 'Ukendt'
        WHEN surface_temp = '{Befæstet,Ubefæstet}' THEN 'Befæstet'
        WHEN surface_temp = '{Ubefæstet,Befæstet}' THEN 'Befæstet'
    END
WHERE
    matched = TRUE;

DO $$
DECLARE
    category_temp_null INT;

BEGIN
    SELECT
        count(*) INTO category_temp_null
    FROM
        osm_road_edges
    WHERE
        geodk_category IS NOT NULL
        AND category_temp IS NULL;

ASSERT category_temp_null = 0,
'Issue with classification';

END $$;

DO $$
DECLARE
    surface_temp_null INT;

BEGIN
    SELECT
        count(*) INTO surface_temp_null
    FROM
        osm_road_edges
    WHERE
        geodk_surface IS NOT NULL
        AND surface_temp IS NULL;

ASSERT surface_temp_null = 0,
'Issue with classification';

END $$;

UPDATE
    osm_road_edges
SET
    geodk_category = category_temp
WHERE
    matched = TRUE;

UPDATE
    osm_road_edges
SET
    geodk_surface = surface_temp
WHERE
    matched = TRUE;

ALTER TABLE
    osm_road_edges DROP COLUMN category_temp,
    DROP COLUMN surface_temp;

CREATE VIEW matching_geodk_osm._cykelsti_nodes AS (
    SELECT
        source AS node
    FROM
        osm_road_edges
    WHERE
        matched IS TRUE
        AND geodk_category = 'Cykelsti langs vej'
    UNION
    SELECT
        target AS node
    FROM
        osm_road_edges
    WHERE
        matched IS TRUE
        AND geodk_category = 'Cykelsti langs vej'
);

UPDATE
    osm_road_edges
SET
    geodk_category = 'Cykelsti langs vej'
WHERE
    source IN (
        SELECT
            node
        FROM
            matching_geodk_osm._cykelsti_nodes
    )
    AND target IN (
        SELECT
            node
        FROM
            matching_geodk_osm._cykelsti_nodes
    )
    AND matched IS TRUE
    AND geodk_category IS NULL;

CREATE VIEW matching_geodk_osm._cykelbane_nodes AS (
    SELECT
        source AS node
    FROM
        osm_road_edges
    WHERE
        matched IS TRUE
        AND geodk_category = 'Cykelbane langs vej'
    UNION
    SELECT
        target AS node
    FROM
        osm_road_edges
    WHERE
        matched IS TRUE
        AND geodk_category = 'Cykelbane langs vej'
);

UPDATE
    osm_road_edges
SET
    geodk_category = 'Cykelbane langs vej'
WHERE
    source IN (
        SELECT
            node
        FROM
            matching_geodk_osm._cykelbane_nodes
    )
    AND target IN (
        SELECT
            node
        FROM
            matching_geodk_osm._cykelbane_nodes
    )
    AND matched IS TRUE
    AND geodk_category IS NULL;

CREATE VIEW matching_geodk_osm._befaestet_nodes AS (
    SELECT
        source AS node
    FROM
        osm_road_edges
    WHERE
        matched IS TRUE
        AND geodk_surface = 'Befæstet'
    UNION
    SELECT
        target AS node
    FROM
        osm_road_edges
    WHERE
        matched IS TRUE
        AND geodk_surface = 'Befæstet'
);

UPDATE
    osm_road_edges
SET
    geodk_surface = 'Befæstet'
WHERE
    source IN (
        SELECT
            node
        FROM
            matching_geodk_osm._befaestet_nodes
    )
    AND target IN (
        SELECT
            node
        FROM
            matching_geodk_osm._befaestet_nodes
    )
    AND matched IS TRUE
    AND geodk_surface IS NULL;

CREATE VIEW matching_geodk_osm._ubefaestet_nodes AS (
    SELECT
        source AS node
    FROM
        osm_road_edges
    WHERE
        matched IS TRUE
        AND geodk_surface = 'Ubefæstet'
    UNION
    SELECT
        target AS node
    FROM
        osm_road_edges
    WHERE
        matched IS TRUE
        AND geodk_surface = 'Ubefæstet'
);

UPDATE
    osm_road_edges
SET
    geodk_surface = 'Ubefæstet'
WHERE
    source IN (
        SELECT
            node
        FROM
            matching_geodk_osm._ubefaestet_nodes
    )
    AND target IN (
        SELECT
            node
        FROM
            matching_geodk_osm._ubefaestet_nodes
    )
    AND matched IS TRUE
    AND geodk_surface IS NULL;

UPDATE
    osm_road_edges
SET
    geodk_surface = 'Befæstet'
WHERE
    (
        source IN (
            SELECT
                node
            FROM
                matching_geodk_osm._befaestet_nodes
        )
        OR target IN (
            SELECT
                node
            FROM
                matching_geodk_osm._befaestet_nodes
        )
    )
    AND matched IS TRUE
    AND geodk_surface IS NULL;

UPDATE
    osm_road_edges
SET
    geodk_category = 'Cykelbane langs vej'
WHERE
    (
        source IN (
            SELECT
                node
            FROM
                matching_geodk_osm._cykelbane_nodes
        )
        OR target IN (
            SELECT
                node
            FROM
                matching_geodk_osm._cykelbane_nodes
        )
    )
    AND matched IS TRUE
    AND geodk_category IS NULL;

UPDATE
    osm_road_edges
SET
    geodk_category = 'Cykelsti langs vej'
WHERE
    (
        source IN (
            SELECT
                node
            FROM
                matching_geodk_osm._cykelsti_nodes
        )
        OR target IN (
            SELECT
                node
            FROM
                matching_geodk_osm._cykelsti_nodes
        )
    )
    AND matched IS TRUE
    AND geodk_category IS NULL;

DO $$
DECLARE
    matched_no_class INT;

BEGIN
    SELECT
        count(*) INTO matched_no_class
    FROM
        osm_road_edges
    WHERE
        geodk_category IS NULL
        AND matched IS TRUE;

ASSERT matched_no_class = 0,
'Issue with category of matched edges';

END $$;

DO $$
DECLARE
    matched_no_surface INT;

BEGIN
    SELECT
        count(*) INTO matched_no_surface
    FROM
        osm_road_edges
    WHERE
        geodk_surface IS NULL
        AND matched IS TRUE;

ASSERT matched_no_surface = 0,
'Issue with surface of matched edges';

END $$;

DO $$
DECLARE
    matched_error_class INT;

BEGIN
    SELECT
        count(*) INTO matched_error_class
    FROM
        osm_road_edges
    WHERE
        geodk_category IS NOT NULL
        AND matched IS FALSE;

ASSERT matched_error_class = 0,
'Issue with category of matched edges';

END $$;

DO $$
DECLARE
    matched_error_surface INT;

BEGIN
    SELECT
        count(*) INTO matched_error_surface
    FROM
        osm_road_edges
    WHERE
        geodk_surface IS NOT NULL
        AND matched IS FALSE;

ASSERT matched_error_surface = 0,
'Issue with surface of matched edges';

END $$;