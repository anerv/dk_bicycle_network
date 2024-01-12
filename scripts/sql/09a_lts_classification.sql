ALTER TABLE
    osm_road_edges
ADD
    COLUMN bicycle_class INTEGER DEFAULT NULL,
ADD
    COLUMN lts INTEGER DEFAULT NULL;

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
'Edges missing bicycle class';

END $$;

-- *** LTS 1 ***
-- OBS - LTS 1 does not consider whether cycling is allowed or not
UPDATE
    osm_road_edges
SET
    lts = 1
WHERE
    bicycle_class = 1
    OR (
        -- implicit also includes bicycle class 3 here
        maxspeed_assumed <= 30
        AND lanes_assumed <= 2
        AND (
            bicycle_infrastructure_final IS TRUE
            OR highway NOT IN (
                'path',
                'bridleway',
                'footway',
                'pedestrian'
            )
        )
    )
    OR (
        -- implicit also includes bicycle class 3 here
        maxspeed_assumed <= 20
        AND cycling_allowed IS TRUE
        AND lanes_assumed <= 3
        AND (
            bicycle_infrastructure_final IS TRUE
            OR highway NOT IN (
                'path',
                'bridleway',
                'footway',
                'pedestrian'
            )
        )
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
    lts = 2
WHERE
    (
        bicycle_class = 2 --AND maxspeed_assumed > 40
        AND maxspeed_assumed <= 50
        AND lanes_assumed >= 3
        AND lanes_assumed <= 4
    )
    OR (
        (
            bicycle_class = 3
            OR bicycle_class IS NULL
        )
        AND maxspeed_assumed > 30
        AND maxspeed_assumed <= 50
        AND lanes_assumed < 4
    )
    OR (
        (
            bicycle_class = 3
            OR bicycle_class IS NULL
        )
        AND maxspeed_assumed >= 30
        AND maxspeed_assumed <= 50
        AND lanes_assumed < 4
        AND lanes_assumed > 2
    );

-- *** LTS 3 ***
UPDATE
    osm_road_edges
SET
    lts = 3
WHERE
    (
        bicycle_class = 2
        AND maxspeed_assumed > 50
        AND maxspeed_assumed <= 60
        AND lanes_assumed < 5
    )
    OR (
        (
            bicycle_class = 3
            OR bicycle_class IS NULL
        )
        AND maxspeed_assumed >= 30
        AND maxspeed_assumed <= 50
        AND lanes_assumed = 4
    );

-- *** LTS 4 ***
UPDATE
    osm_road_edges
SET
    lts = 4
WHERE
    (
        bicycle_class = 2
        AND (
            maxspeed_assumed >= 50
            AND lanes_assumed >= 5
        )
    )
    OR (
        bicycle_class = 2
        AND (maxspeed_assumed >= 70)
    )
    OR (
        (
            bicycle_class = 3
            OR bicycle_class IS NULL
        )
        AND maxspeed_assumed > 50
    )
    OR (
        (
            bicycle_class = 3
            OR bicycle_class IS NULL
        )
        AND lanes_assumed > 4
    );

UPDATE
    osm_road_edges
SET
    lts = 4,
WHERE
    highway IN ('motorway_link')
    AND bicycle_class IS NULL;

-- *** LTS 999 ***
UPDATE
    osm_road_edges
SET
    lts_999 = 999
WHERE
    car_traffic IS FALSE
    AND cycling_allowed IS FALSE
    AND lts IS NULL;

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

-- SET LTS to 0 where cycling is allowed but edges are not part of bicycle infrastructure
UPDATE
    osm_road_edges
SET
    lts = 0
WHERE
    bicycle_infrastructure_final IS FALSE
    AND car_traffic IS FALSE
    AND cycling_allowed IS TRUE
    AND lts IS NULL;

-- TODO: look at edges where lts is null and cycling allowed
-- some pedestrian missing lts - cycle_living_street
-- some pedestrian/paths classified as cyclelanes 
-- some cat crossing