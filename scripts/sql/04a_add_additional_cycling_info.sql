-- Add additional info for LTS classification
ALTER TABLE
    osm_road_edges DROP COLUMN IF EXISTS cycling_allowed,
    DROP COLUMN IF EXISTS car_traffic,
    DROP COLUMN IF EXISTS along_street,
    DROP COLUMN IF EXISTS bicycle_infrastructure_final,
    DROP COLUMN IF EXISTS bicycle_infrastructure_separate;

ALTER TABLE
    osm_road_edges
ADD
    COLUMN cycling_allowed BOOLEAN DEFAULT FALSE,
ADD
    COLUMN car_traffic BOOLEAN DEFAULT FALSE,
ADD
    COLUMN along_street BOOLEAN DEFAULT FALSE,
ADD
    COLUMN bicycle_infrastructure_final BOOLEAN DEFAULT FALSE,
ADD
    COLUMN bicycle_infrastructure_separate BOOLEAN DEFAULT NULL;

-- Fill bicycle_infrastructure_final
UPDATE
    osm_road_edges
SET
    bicycle_infrastructure_final = TRUE
WHERE
    bicycle_infrastructure IS TRUE
    OR matched IS TRUE;

-- Fill bicycle_protected
UPDATE
    osm_road_edges
SET
    bicycle_protected = TRUE
WHERE
    bicycle_protected IS NULL
    AND geodk_category = 'Cykelsti langs vej';

-- Fill column car_traffic
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
        'services',
        'track',
        'unclassified'
    )
    AND (
        access NOT IN (
            'no',
            'restricted',
            'private',
            'foresty',
            'agricultural',
            'customers',
            'residents',
            'delivery',
            'private;customers',
            'permit',
            'permit2'
        )
        OR access IS NULL
    )
    AND (
        motorcar <> 'no'
        OR motorcar IS NULL
    )
    AND (
        motor_vehicle <> 'no'
        OR motor_vehicle IS NULL
    );

-- Fill column cycling_allowed where cycling is ALLOWED
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
            'bicycle_road'
        )
        AND (
            bicycle IS NULL
            OR bicycle NOT IN ('dismount', 'use_sidepath', 'no')
        )
    );

-- Cycling not allowed/possible on steps and other restrictions
UPDATE
    osm_road_edges
SET
    cycling_allowed = FALSE
WHERE
    highway = 'steps'
    OR (
        access IN (
            'no',
            'private',
            'foresty',
            'agricultural',
            'customers',
            'residents',
            'delivery',
            'private;customers',
            'permit',
            'permit2'
        )
        AND (
            bicycle IS NULL
            OR bicycle <> 'yes'
        )
        AND bicycle_infrastructure_final IS FALSE
    )
    OR motorroad = 'yes'
    OR (
        (
            cycleway IN ('separate', 'use_sidepath')
            OR "cycleway:left" IN ('separate', 'use_sidepath')
            OR "cycleway:right" IN ('separate', 'use_sidepath')
            OR "cycleway:both" IN ('separate', 'use_sidepath')
        )
        AND bicycle_infrastructure_final IS FALSE
    );

-- Declassify bicycle infrastructure matched from GeoDK but matched separately
UPDATE
    osm_road_edges
SET
    bicycle_infrastructure_final = FALSE,
    cycling_allowed = FALSE
WHERE
    bicycle_infrastructure IS FALSE --AND cycling_allowed IS FALSE
    AND (
        bicycle IN ('use_sidepath', 'no', 'separate')
        OR cycleway IN ('use_sidepath', 'separate')
        OR "cycleway:left" IN ('use_sidepath', 'separate')
        OR "cycleway:right" IN ('use_sidepath', 'separate')
        OR "cycleway:both" IN ('use_sidepath', 'separate')
    )
    AND bicycle_infrastructure_final IS TRUE
    AND matched IS TRUE;

-- Declassify highways and motorroads classified as bicycle infrastructure only based on GeoDanmark data
UPDATE
    osm_road_edges
SET
    cycling_allowed = FALSE,
    bicycle_infrastructure_final = FALSE
WHERE
    matched IS TRUE
    AND (
        (
            highway IN ('motorway', 'motorway_link')
            AND bicycle_infrastructure IS FALSE
        )
        OR (
            motorroad = 'yes'
            AND bicycle_infrastructure IS FALSE
        )
    );

-- Fill bicycle_infrastructure_separate
UPDATE
    osm_road_edges
SET
    bicycle_infrastructure_separate = TRUE
WHERE
    bicycle_infrastructure_final IS FALSE
    AND (
        bicycle IN ('separate', 'use_sidepath')
        OR cycleway IN ('separate', 'use_sidepath')
        OR "cycleway:left" IN ('separate', 'use_sidepath')
        OR "cycleway:right" IN ('separate', 'use_sidepath')
        OR "cycleway:both" IN ('separate', 'use_sidepath')
    );

-- Fill along_street based on car_traffic and matched columns
--Determining whether the segment of cycling infrastructure runs along a street or not
UPDATE
    osm_road_edges
SET
    along_street = TRUE
WHERE
    car_traffic = TRUE
    OR matched = TRUE;

CREATE TABLE buffered_car_roads AS
SELECT
    ST_Buffer(geometry, 25) AS geometry
FROM
    osm_road_edges
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
        'motorway_link' -- 'service', 'track', ??
        -- 'services'
    )
    AND (
        motorcar <> 'no'
        OR motorcar IS NULL
    )
    AND (
        motor_vehicle <> 'no'
        OR motor_vehicle IS NULL
    );

CREATE TABLE cycleways_points AS WITH cycleways AS (
    SELECT
        id,
        highway,
        bicycle_infrastructure_final,
        cycling_allowed,
        along_street,
        geometry
    FROM
        osm_road_edges
    WHERE
        bicycle_infrastructure IS TRUE
        AND along_street IS FALSE
        AND car_traffic IS FALSE -- highway IN (
        --     'cycleway',
        --     'path',
        --     'footway',
        --     'bridleway'
        -- )
)
SELECT
    id,
    ST_Collect(
        ARRAY [ ST_StartPoint(geometry),
        ST_Centroid(geometry),
        ST_EndPoint(geometry) ]
    ) AS geometry
FROM
    cycleways;

CREATE TABLE exploded_cycle_points AS
SELECT
    id,
    (ST_Dump(geometry)) .geom AS geometry
FROM
    cycleways_points;

CREATE INDEX ex_c_points_geom_idx ON exploded_cycle_points USING GIST (geometry);

CREATE INDEX buffered_car_roads_geom_idx ON buffered_car_roads USING GIST (geometry);

CREATE TABLE points_along_road AS
SELECT
    *
FROM
    exploded_cycle_points AS e
WHERE
    EXISTS(
        SELECT
            1
        FROM
            buffered_car_roads AS b
        WHERE
            ST_Intersects(e.geometry, b.geometry)
    );

CREATE TABLE count_along_car AS
SELECT
    id,
    COUNT(*) AS C
FROM
    points_along_road
GROUP BY
    id;

UPDATE
    osm_road_edges o
SET
    along_street = TRUE
FROM
    count_along_car C
WHERE
    o.id = C .id
    AND C .c = 3;

DO $$
DECLARE
    cycling_classification INT;

BEGIN
    SELECT
        COUNT(*) INTO cycling_classification
    FROM
        osm_road_edges
    WHERE
        bicycle_infrastructure_final IS TRUE
        AND cycling_allowed IS FALSE;

ASSERT cycling_classification = 0,
'Issue with bicycle classification';

END $$;

DROP TABLE IF EXISTS buffered_car_roads;

DROP TABLE IF EXISTS cycleways_points;

DROP TABLE IF EXISTS exploded_cycle_points;

DROP TABLE IF EXISTS points_along_road;

DROP TABLE IF EXISTS count_along_car;