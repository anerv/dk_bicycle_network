ALTER TABLE
    osm_road_edges
ADD
    COLUMN bicycle_surface_assumed VARCHAR DEFAULT NULL,
ADD
    COLUMN lanes_assumed INTEGER DEFAULT NULL,
ADD
    COLUMN centerline_assumed BOOLEAN DEFAULT NULL,
ADD
    COLUMN maxspeed_assumed INTEGER DEFAULT NULL;

-- SURFACE
UPDATE
    osm_road_edges
SET
    bicycle_surface_assumed = "cycleway:surface"
WHERE
    "cycleway:surface" IS NOT NULL;

UPDATE
    osm_road_edges
SET
    bicycle_surface_assumed = surface
WHERE
    surface IS NOT NULL
    AND bicycle_surface_assumed IS NULL;

UPDATE
    osm_road_edges
SET
    bicycle_surface_assumed = 'paved'
WHERE
    bicycle_surface_assumed IS NULL
    AND geodk_surface = 'Befæstet';

-- Cycling surface is assumed paved if along a car street    
UPDATE
    osm_road_edges
SET
    bicycle_surface_assumed = 'paved'
WHERE
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
        --'service',
        'motorway',
        'motorway_link'
    )
    AND bicycle_surface_assumed IS NULL
    AND cycling_allowed IS TRUE;

-- LANES assumed
-- Based on Wasserman, https: / / wiki.openstreetmap.org / wiki / Key :lanes and most typical values for each category
UPDATE
    osm_road_edges
SET
    lanes_assumed = CASE
        WHEN highway IN (
            'residential',
            'unclassified',
            'service',
            'tertiary',
            'secondary',
            'primary'
        ) THEN 2
        WHEN highway IN ('trunk', 'motorway') THEN 6
        WHEN highway IN (
            'cyclestreet',
            'bicycle_road',
            'living_street',
            'track'
        ) THEN 2
        WHEN highway IN ('path', 'bridleway') THEN 1
        WHEN highway LIKE '%_link' THEN 2
        ELSE lanes_assumed
    END;

UPDATE
    osm_road_edges
SET
    lanes_assumed = lanes :: INT
WHERE
    lanes IS NOT NULL;

UPDATE
    osm_road_edges
SET
    lanes_assumed = "lanes:backward" :: INT + "lanes:forward" :: INT
WHERE
    lanes IS NULL
    AND "lanes:backward" IS NOT NULL
    AND "lanes:forward" IS NOT NULL;

UPDATE
    osm_road_edges
SET
    lanes_assumed = "lanes:forward" :: INT
WHERE
    lanes IS NULL
    AND "lanes:backward" IS NULL
    AND "lanes:forward" IS NOT NULL;

UPDATE
    osm_road_edges
SET
    lanes_assumed = "lanes:backward" :: INT
WHERE
    lanes IS NULL
    AND "lanes:forward" IS NULL
    AND "lanes:backward" IS NOT NULL;

DO $$
DECLARE
    car_lanes_null INT;

BEGIN
    SELECT
        COUNT(*) INTO car_lanes_null
    FROM
        osm_road_edges
    WHERE
        lanes_assumed IS NULL
        AND car_traffic IS TRUE;

ASSERT car_lanes_null = 0,
'Assumed lanes missing';

END $$;

-- SPEED ASSUMED
UPDATE
    osm_road_edges
SET
    maxspeed_assumed = CASE
        WHEN highway = 'living_street' THEN 15
        WHEN highway IN ('bicycle_road', 'cyclestreet') THEN 30
        WHEN bicycle_road IN ('yes') THEN 30
        WHEN cyclestreet IN ('yes') THEN 30
        WHEN highway IN ('residential') THEN 50
        WHEN highway IN ('track', 'service') THEN 50
        WHEN highway IN (
            'trunk',
            'primary',
            'secondary',
            'tertiary',
            'unclassified',
            'trunk_link',
            'primary_link',
            'secondary_link',
            'tertiary_link'
        ) THEN 80
        WHEN highway IN ('motorway', 'motorway_link') THEN 130
    END;

-- Inside city limits: default is 50 km/h
UPDATE
    osm_road_edges
SET
    maxspeed_assumed = 50
WHERE
    urban IN ('1', '3')
    AND highway IN (
        'residential',
        'trunk',
        'primary',
        'secondary',
        'tertiary',
        'unclassified',
        'service',
        'trunk_link',
        'primary_link',
        'secondary_link',
        'tertiary_link'
    );

UPDATE
    osm_road_edges
SET
    maxspeed_assumed = maxspeed :: INT
WHERE
    maxspeed IS NOT NULL
    AND maxspeed NOT IN ('none', 'DK:urban', 'signals');

UPDATE
    osm_road_edges
SET
    maxspeed_assumed = CASE
        WHEN maxspeed_assumed = 6 THEN 5
        WHEN maxspeed_assumed = 79 THEN 80
        WHEN maxspeed_assumed = 12 THEN 15
        ELSE maxspeed_assumed
    END;

DO $$
DECLARE
    speed_null INT;

BEGIN
    SELECT
        COUNT(*) INTO speed_null
    FROM
        osm_road_edges
    WHERE
        maxspeed_assumed IS NULL
        AND car_traffic IS TRUE;

ASSERT speed_null = 0,
'Assumed speeds missing';

END $$;

-- CENTER LINE ASSUMED
UPDATE
    osm_road_edges
SET
    centerline_assumed = CASE
        WHEN highway IN (
            'residential',
            'service',
            'unclassified',
            'living_street',
            'bicycle_road',
            'cyclestreet'
        ) THEN FALSE
        WHEN highway IN (
            'track',
            'trunk',
            'primary',
            'secondary',
            'tertiary',
            'trunk_link',
            'primary_link',
            'secondary_link',
            'tertiary_link',
            'motorway',
            'motorway_link'
        ) THEN TRUE
    END;

DO $$
DECLARE
    centerline_null INT;

BEGIN
    SELECT
        COUNT(*) INTO centerline_null
    FROM
        osm_road_edges
    WHERE
        centerline_assumed IS NULL
        AND car_traffic IS TRUE;

ASSERT centerline_null = 0,
'Assumed speeds missing';

END $$;