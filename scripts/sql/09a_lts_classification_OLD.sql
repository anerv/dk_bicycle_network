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

-- *** LTS 2 ****
-- IF bicycle class 2:
-- speed of max 40
-- If centerline: max 4 lanes, 2 if oneway
-- No centerline: max 2 lanes, 1 if oneway
-- If bicycle class 3:
-- Speed max 50 km/h + With center line, more than 4 lanes (more than 2 if oneway)
-- 40 km, No center line (4 or more lanes (2 or more if oneway))
--
UPDATE
    osm_road_edges
SET
    lts_2 = 2
WHERE
    (
        bicycle_class = 2
        AND maxspeed_assumed <= 40
    )
    OR (
        bicycle_class = 2
        AND (
            centerline_assumed IS TRUE
            AND (
                lanes_assumed <= 4
                AND oneway NOT IN ('yes', 'True', 'true', '1')
                OR (
                    lanes_assumed <= 2
                    AND oneway IN ('yes', 'True', 'true', '1')
                )
            )
        )
    );

UPDATE
    osm_road_edges
SET
    lts_2 = 2
WHERE
    bicycle_class = 3
    AND (
        centerline_assumed IS TRUE
        AND maxspeed_assumed <= 50
        AND lanes_assumed <= 3
    )
    OR (
        centerline_assumed IS FALSE
        AND maxspeed_assumed <= 40
        AND lanes_assumed <= 2
    );

-- *** LTS 3 ***
-- IF bicycle category 2:
-- Max speed of 60 km/h
-- If centerline: More than four lanes (more than 2 if oneway)
-- If no centerline (4 lanes (2 if oneway))
-- IF bicycle category 3:
-- Max speed 70 km if no centerline
-- Max speed 50 km if centerline
-- Max 3 lanes if no centerline
-- Max 4 lanes if centerline
--
UPDATE
    osm_road_edges
SET
    lts_3 = 3
WHERE
    bicycle_class = 2
    AND (
        maxspeed_assumed >= 60
        OR (
            centerline_assumed IS TRUE
            AND (
                lanes_assumed > 4
                OR (
                    lanes_assumed > 2
                    AND oneway IN ('yes', 'True', 'true', '1')
                )
            )
        )
        OR (
            centerline_assumed IS FALSE
            AND (
                lanes_assumed <= 4
                OR (
                    lanes_assumed <= 2
                    AND oneway IN ('yes', 'True', 'true', '1')
                )
            )
        )
    );

UPDATE
    osm_road_edges
SET
    lts_3 = 3
WHERE
    bicycle_class = 3
    AND (
        centerline_assumed IS FALSE
        AND (
            lanes_assumed <= 3
            OR maxspeed_assumed <= 50
        )
    )
    OR (
        centerline_assumed IS TRUE
        AND (
            lanes_assumed <= 4
            OR maxspeed_assumed <= 70
        )
    );

-- *** LTS 4 ***
-- If bicycle category 2, speed of 70 km or more or two or more lanes per direction
-- If bicycle category 3, all roads with a speed of 60 or more or four or more lanes in total
--
UPDATE
    osm_road_edges
SET
    lts_4 = 4
WHERE
    bicycle_class = 2
    AND (
        maxspeed_assumed >= 70
        OR (
            lanes_assumed >= 4
            AND oneway IN ('no', 'False', 'false', '0')
        )
        OR (
            lanes_assumed >= 2
            AND oneway IN ('yes', 'True', 'true', '1')
        )
    );

UPDATE
    osm_road_edges
SET
    lts_4 = 4
WHERE
    bicycle_class = 3
    AND (
        lanes_assumed >= 4
        OR maxspeed_assumed >= 60
    );

-- *** LTS 1 ****
UPDATE
    osm_road_edges
SET
    lts_1 = 1
WHERE
    bicycle_class = 1
    AND bicycle_infrastructure_final = TRUE;

-- *** LTS '5' WHERE cycling is not allowed but car traffic is **
-- THIS WILL ALSO INCLUDE ROADS WITH LOW LTS BUT BICYCLE INFRA MAPPED SEPARATELY
UPDATE
    osm_road_edges
SET
    lts_5 = 5
WHERE
    cycling_allowed IS FALSE
    AND car_traffic IS TRUE;

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