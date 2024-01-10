ALTER TABLE
    osm_road_edges
ADD
    COLUMN lts INTEGER DEFAULT NULL;

ALTER TABLE
    osm_road_edges
ADD
    COLUMN lts_1 INTEGER DEFAULT NULL,
ADD
    COLUMN lts_2 INTEGER DEFAULT NULL,
ADD
    COLUMN lts_3 INTEGER DEFAULT NULL,
ADD
    COLUMN lts_4 INTEGER DEFAULT NULL,
ADD
    COLUMN lts_5 INTEGER DEFAULT NULL,
ADD
    COLUMN lts_999 INTEGER DEFAULT NULL;

-- FIX highway = pedestrian and cycleway = lane (LTS issue)
-- fix highway = track and category = lane (because of matching) (LTS issue) -- lts mixed traffic
-- residential, 5 lanes, bicycle lanes (LTS issue)
-- FIX: why no lts 2 lol?
-- FIX: too many in lts 4??
--
--Assign bicycle class
UPDATE
    osm_road_edges
SET
    bicycle_class = CASE
        WHEN bicycle_category = 'shared_track' THEN 1
        WHEN bicycle_category = 'cycleway' THEN 1
        WHEN bicycle_category = 'cycletrack' THEN 1
        WHEN bicycle_category = 'cyclelane' THEN 2
        WHEN bicycle_category = 'shared_busway' THEN 2
        WHEN bicycle_category = 'cycle_living_street' THEN 3
        WHEN bicycle_category = 'crossing' THEN 3
        WHEN bicycle_category = 'shared_lane' THEN 3
        WHEN bicycle_category IS NULL
        AND cycling_allowed IS TRUE THEN 3
    END;

DO $$
DECLARE
    bike_class_null INT;

BEGIN
    SELECT
        COUNT(*) INTO bike_class_null
    FROM
        osm_road_edges
    WHERE
        cycling_allowed IS TRUE
        AND bicycle_class IS NULL;

ASSERT bike_class_null = 0,
'Edges missing bicycle category';

END $$;

-- *** LTS 1 ***
UPDATE
    osm_road_edges
SET
    lts_1 = 1
WHERE
    bicycle_class = 1
    OR maxspeed_assumed <= 30
    OR (
        bicycle_class = 2
        AND maxspeed_assumed <= 40
    )
    OR (
        bicycle_class = 2
        AND maxspeed_assumed <= 50
        AND lanes_assumed <= 2
    );

-- *** LTS 2 ***
UPDATE
    osm_road_edges
SET
    lts_2 = 2
WHERE
    (
        bicycle_class = 2
        AND maxspeed_assumed > 40
        AND maxspeed_assumed <= 50
        AND lanes_assumed > 3
        AND lanes_assumed <= 4
    )
    OR (
        bicycle_class = 3
        AND maxspeed_assumed > 30
        AND maxspeed_assumed <= 50
        AND highway IN ('residential') -- service??
    );

-- *** LTS 3 ***
UPDATE
    osm_road_edges
SET
    lts_3 = 3
WHERE
    (
        bicycle_class = 2
        AND maxspeed_assumed > 50
        AND maxspeed_assumed <= 60
    )
    OR (
        bicycle_class = 3
        AND maxspeed_assumed > 30
        AND maxspeed_assumed <= 50
        AND highway NOT IN ('residential') -- service??
    )
    OR (
        bicycle_class = 3
        AND lanes_assumed >= 4
    );

-- *** LTS 4 ***
UPDATE
    osm_road_edges
SET
    lts_4 = 4
WHERE
    (
        bicycle_class = 2
        AND maxspeed_assumed > 60
        AND maxspeed_assumed <= 70
    )
    OR (
        bicycle_class = 3
        AND maxspeed_assumed > 50
    )
    OR (
        bicycle_class = 3
        AND lanes_assumed > 4
    );

-- *** LTS 999 ***
UPDATE
    osm_road_edges
SET
    lts_999 = 999
WHERE
    car_traffic IS FALSE
    AND cycling_allowed IS FALSE;

-- **
-- TODO: WHAT TO DO WITH CYCLING ALLOWED NO??
-- ***
UPDATE
    DO $$
DECLARE
    lts_car_null INT;

BEGIN
    SELECT
        COUNT(*) INTO lts_car_null
    FROM
        osm_road_edges
    WHERE
        lts IS NULL
        AND car_traffic IS TRUE;

ASSERT lts_car_null = 0,
'Car edges missing LTS value';

END $$;

UPDATE
    osm_road_edges
SET
    lts_999 = 999
WHERE
    car_traffic IS FALSE
    AND cycling_allowed IS FALSE;

--make sure paths and tracks with bad surface or bicycle no are not included
UPDATE
    osm_road_edges
SET
    lts_999 = 999
WHERE
    bicycle_infrastructure_final IS FALSE
    AND highway IN (
        'path',
        'track',
        'bridleway',
        'footway',
        'pedestrian'
    );

--bicycle_surface_assumed IN (
--     'asphalt',
--     'bricks',
--     'chipseal',
--     'cobblestone',
--     'compacted',
--     'concrete',
--     'concrete:lanes',
--     'concrete:plates',
--     'fine_gravel',
--     'grass_paver',
--     'metal',
--     'metal_grid',
--     'paved',
--     'paving_stones',
--     'pebblestone',
--     'plastic',
--     'sett',
--     'sp',
--     'steel',
--     'stone',
--     'tartan',
--     'tree',
--     'unpaved',
--     'wood'
-- )
---
-- *** LTS 1 ****
-- if protected bike infra = LTS1
-- if speed max 50 and unprotected bike infra -- LTS 1
-- if speed max 40 and no bike infra/class 3 -- LTS 1
-- *** LTS 2 ****
-- if residential and no bike infra -- LTS 2
--if speed above XXXX and no bike infra --> lts 4
--if lanes above XXXX and no bike infra --> lts 4
--IF speed above XXXX AND unprotected bike infra --> lts 
--IF lanes above XXXX AND no bike infra --> lts 4