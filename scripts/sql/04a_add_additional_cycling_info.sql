-- Add additional info for LTS classification
ALTER TABLE
    osm_roads
ADD
    COLUMN cycling_allowed BOOLEAN DEFAULT NULL,
ADD
    COLUMN car_traffic BOOLEAN DEFAULT NULL,
    --ADD COLUMN bike_separated VARCHAR DEFAULT NULL,
ADD
    COLUMN along_street BOOLEAN DEFAULT NULL;

-- *** Fill column car_traffic ***
UPDATE
    osm_roads
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
    osm_roads
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
    OR bicycle_infrastructure_all = TRUE
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
    osm_roads
SET
    cycling_allowed = FALSE
WHERE
    bicycle IN ('no', 'dismount', 'use_sidepath')
    OR (
        highway IN ('motorway', 'motorway_link')
        AND cycling_infra_new = 'no'
    );

-- *** FILL COLUMN ALONG STREET ***
--Determining whether the segment of cycling infrastructure runs along a street or not
UPDATE
    osm_roads
SET
    along_street = TRUE
WHERE
    car_traffic = TRUE;

UPDATE
    osm_roads
SET
    along_street = TRUE
WHERE
    geodk_bike IS NOT NULL;

-- UPDATE
--     osm_roads
-- SET
--     along_street = FALSE
-- WHERE
--     cycling_infra_new = 'yes'
--     AND along_street IS NULL;
-- Capturing cycleways digitized as individual ways but still running parallel to a street
CREATE VIEW cycleways AS (
    SELECT
        name,
        highway,
        cycling_infrastructure,
        along_street
    FROM
        osm_roads
    WHERE
        highway = 'cycleway'
);

CREATE VIEW car_roads AS (
    SELECT
        name,
        highway,
        geometry
    FROM
        osm_roads
    WHERE
        car_traffic IS TRUE
);

-- UPDATE cycleways c SET along_street = 'true'
--     FROM car_roads cr WHERE c.name = cr.name
-- ;
CREATE TABLE buffered_car_roads AS (
    SELECT
        (ST_Dump(geom)).geom
    FROM
        (
            SELECT
                ST_Union(ST_Buffer(geometry, 20)) AS geom
            FROM
                car_roads
        ) cr
);

CREATE INDEX buffer_geom_idx ON buffered_car_roads USING GIST (geom);

CREATE INDEX osm_edges_geom_idx ON osm_roads USING GIST (geometry);

CREATE TABLE intersecting_cycle_roads AS (
    SELECT
        o.osm_id,
        o.geometry
    FROM
        osm_roads o,
        buffered_car_roads br
    WHERE
        o.cycling_infra_new = 'yes'
        AND ST_Intersects(o.geometry, br.geom)
);

CREATE TABLE cycle_infra_points AS (
    SELECT
        osm_id,
        ST_Collect(
            ARRAY [ST_StartPoint(geometry), ST_Centroid(geometry), ST_EndPoint(geometry)]
        ) AS geometry
    FROM
        intersecting_cycle_roads
);

CREATE INDEX cycle_points_geom_idx ON cycle_infra_points USING GIST (geometry);

CREATE TABLE cycling_cars AS (
    SELECT
        c.osm_id,
        c.geometry
    FROM
        cycle_infra_points c,
        buffered_car_roads br
    WHERE
        ST_CoveredBy(c.geometry, br.geom)
);

UPDATE
    osm_roads o
SET
    along_street = TRUE
FROM
    cycling_cars c
WHERE
    o.osm_id = c.osm_id;