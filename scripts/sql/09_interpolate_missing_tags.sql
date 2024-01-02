ALTER TABLE
    osm_road_edges
ADD
    COLUMN bicycle_surface_assumed VARCHAR DEFAULT NULL,
ADD
    COLUMN lanes_assumed INTEGER DEFAULT NULL,
ADD
    COLUMN centerline_assumed BOOLEAN DEFAULT NULL,
ADD
    COLUMN maxspeed_assumed VARCHAR DEFAULT NULL,
ADD
    COLMUN bicycle_class INTEGER DEFAULT NULL;

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
UPDATE
    osm_road_edges
SET
    lanes_assumed = lanes
WHERE
    lanes IS NOT NULL;

UPDATE
    osm_road_edges
SET
    lanes_assumed = CASE
        WHEN highway IN ('residential', 'unclassified', 'service')
        AND lanes IS NULL THEN 2
        WHEN highway = 'tertiary'
        AND lanes IS NULL THEN 3
        WHEN highway = 'secondary'
        AND lanes IS NULL THEN 4
        WHEN highway in ('primary', 'trunk', 'motorway')
        AND lanes IS NULL THEN 6
        WHEN highway IN ('cyclestreet', 'bicycle_road', 'living_street')
        AND lanes IS NULL THEN 2
        WHEN highway IN ('path', 'bridleway', 'track')
        AND lanes IS NULL THEN 1
        WHEN highway LIKE '%_link'
        AND lanes IS NULL THEN 1
    END;

-- TODO: tracks - is 2 not too much?
-- TODO: are there any with no lanes assumed?
--
-- SPEED ASSUMED
UPDATE
    osm_road_edges
SET
    maxspeed_assumed = CASE
        WHEN highway = 'living_street' THEN 15
        WHEN highway IN ('bicycle_road', 'cyclestreet') THEN 30
        WHEN highway IN (
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
        ) THEN 80
        WHEN highway IN ('motorway', 'motorway_link') THEN 130
    END;

-- Inside city limits: default is 50 km/h
UPDATE
    osm_road_edges
SET
    maxspeed_assumed = 50
WHERE
    urban IN ('urban', 'sub-semi-urban')
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
    maxspeed_assumed = maxspeed
WHERE
    maxspeed IS NOT NULL;

ALTER TABLE
    osm_road_edges
ADD
    COLUMN speed_diff INTEGER DEFUALT NULL:
UPDATE
    osm_road_edges
SET
    speed_diff = maxspeed - maxspeed_assumed
WHERE
    maxspeed IS NOT NULL;

-- check if there are any with no assumed speed
-- CHECK - how often speed assumed is the same as actual max speed
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

-- Classify bicycle class
UPDATE
    osm_road_edges
SET
    bicycle_class = CASE
        WHEN highway = 'cycleway'
        AND along_street IS FALSE THEN 1
        WHEN highway = 'path'
        AND cycling_allowed IS TRUE THEN 1 -- todo: make use of surface?
        WHEN highway = 'track'
        AND cycling_allowed IS TRUE THEN 1 -- todo: make use of surface??
        WHEN highway IN ('bicycle_road', 'cyclestreet') THEN 3
        WHEN
    END;

-- make use of surface?
-- TODO: check if cars are ever allowed on tracks???
-- DIFFERENCES FROM WASSERMAN: assumption about centerline on unclassified, classification of tracks