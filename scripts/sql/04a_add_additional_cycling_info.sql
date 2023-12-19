-- Add additional info for LTS classification
ALTER TABLE
    osm_road_edges
ADD
    COLUMN cycling_allowed BOOLEAN DEFAULT NULL,
ADD
    COLUMN car_traffic BOOLEAN DEFAULT NULL,
ADD
    COLUMN along_street BOOLEAN DEFAULT NULL,
ADD
    COLUMN bicycle_infrastructure_final BOOLEAN DEFAULT NULL;

-- *** Fill bicycle_infra_final based on matching ***
UPDATE
    osm_road_edges
SET
    bicycle_infra_final = TRUE
WHERE
    bicycle_infrastructure IS TRUE
    OR matched IS TRUE;

UPDATE
    osm_road_edges
SET
    protected = TRUE
WHERE
    protected IS NULL
    AND geodk_category = 'Cykelsti langs vej';

-- *** Fill column car_traffic ***
UPDATE
    osm_road_edges
SET
    car_traffic = TRUE
WHERE
    highway IN (
        'busway',
        'trunk',
        'trunk_link',
        'tertiary',
        'tertiary_link',
        'secondary',
        'secondary_link',
        'living_street',
        'primary',
        'primary_link',
        'residential',
        'motorway',
        'motorway_link',
        'service',
        'services'
    )
    OR highway = 'unclassified'
    AND (
        'name' IS NOT NULL
        AND (
            access IS NULL
            OR access NOT IN ('no', 'restricted')
        )
        AND motorcar != 'no'
        AND motor_vehicle != 'no'
    )
    OR highway = 'unclassified'
    AND (
        (maxspeed :: integer > 15)
        AND (
            motorcar != 'no'
            OR motorcar is NULL
        )
        AND (
            motor_vehicle != 'no'
            OR motor_vehicle IS NULL
        )
    );

-- *** Fill column cycling allowed ***
UPDATE
    osm_road_edges
SET
    cycling_allowed = TRUE
WHERE
    bicycle IN (
        'yes',
        'permissive',
        'ok',
        'allowed',
        'designated'
    )
    OR bicycle_infrastructure_final = TRUE
    OR (
        highway IN (
            'trunk',
            'trunk_link',
            'tertiary',
            'tertiary_link',
            'secondary',
            'secondary_link',
            'living_street',
            'primary',
            'primary_link',
            'residential',
            'service',
            'unclassified',
            'path',
            'track',
            'cyclestreet',
            'bicyccle_road'
        )
        AND (
            access IS NULL
            OR access NOT IN ('no', 'restricted')
        )
        AND (
            bicycle IS NULl
            OR bicycle NOT IN ('no', 'dismount', 'use_sidepath')
        )
    );

UPDATE
    osm_road_edges
SET
    cycling_allowed = FALSE
WHERE
    bicycle IN ('no', 'dismount', 'use_sidepath')
    OR (
        highway IN ('motorway', 'motorway_link')
        AND bicycle_infra_final = FALSE
    );

-- *** FILL COLUMN ALONG STREET ***
--Determining whether the segment of cycling infrastructure runs along a street or not
UPDATE
    osm_road_edges
SET
    along_street = TRUE
WHERE
    car_traffic = TRUE;

UPDATE
    osm_road_edges
SET
    along_street = TRUE
WHERE
    matched IS TRUE;

-- Capturing cycleways digitized as individual ways but still running parallel to a street
-- Get all bicycle infrastructure mapped with own geometries
-- TODO: confirm that it only is this subsection that has not been classified as along street yet
CREATE TABLE cycleways AS (
    SELECT
        name,
        highway,
        bicycle_infrastructure_final,
        along_street
    FROM
        osm_road_edges
    WHERE
        highway IN ('cycleway', 'path', 'track')
        AND bicycle_infrastructure_final IS TRUE
);

CREATE TABLE buffered_car_roads AS (
    SELECT
        (ST_Dump(geom)) .geom
    FROM
        (
            SELECT
                ST_Union(ST_Buffer(geometry, 20)) AS geom
            FROM
                osm_road_edges
            WHERE
                car_traffic IS TRUE
        ) cr
);

CREATE INDEX buffer_geom_idx ON buffered_car_roads USING GIST (geom);

CREATE INDEX cycleways_geom_idx ON cycleways USING GIST (geometry);

-- First find cycleways that intersects a car buffer
WITH intersecting_cycleways AS (
    SELECT
        c .id,
        c .geometry
    FROM
        cycleways c,
        buffered_car_roads br
    WHERE
        ST_Intersects(o.geometry, br.geom)
) CREATE TABLE cycleways_points AS (
    SELECT
        id,
        ST_Collect(
            ARRAY [ ST_StartPoint(geometry),
            ST_Centroid(geometry),
            ST_EndPoint(geometry) ]
        ) AS geometry
    FROM
        intersecting_cycleways
);

CREATE INDEX cycle_points_geom_idx ON cycleways_points USING GIST (geometry);

-- Then find cycleways where both start, end and mid-point are within a car buffer
CREATE VIEW cycling_cars AS (
    SELECT
        c .id,
        c .geometry
    FROM
        cycle_infra_points c,
        buffered_car_roads br
    WHERE
        ST_CoveredBy(c .geometry, br.geom)
);

UPDATE
    osm_road_edges o
SET
    along_street = TRUE
FROM
    cycling_cars c
WHERE
    o.id = c .id;

-- TODO: set along street = false if not in cycling_cars?
--
-- TODO: confirm that cycling_allowed, car_traffic and along_street are all filled out
-- find a way to fill out null values
DROP VIEW cycling_cars;

DROP TABLE buffered_car_roads;

DROP TABLE cycleways;