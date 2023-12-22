ALTER TABLE
    osm_road_edges
ADD
    COLUMN bicycle_surface_assumed VARCHAR DEFAULT NULL,
ADD
    COLUMN lanes_assumed INT DEFAULT NULL,
ADD
    COLUMN centerline_assumed BOOLEAN DEFAULT NULL,
ADD
    COLUMN speed_assumed VARCHAR DEFAULT NULL;

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

-- TODO:
-- LANES assumed
-- SPEED ASSUMED
-- center line assumed
-- classify cycleways into different categories