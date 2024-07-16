ALTER TABLE
    osm_road_edges DROP COLUMN IF EXISTS bicycle_class,
    DROP COLUMN IF EXISTS lts;

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
        WHEN bicycle_category = 'cycleway_shared' THEN 1
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
                'pedestrian',
                'steps'
            )
        )
    )
    OR (
        -- implicit also includes bicycle class 3 here
        maxspeed_assumed <= 20 --AND cycling_allowed IS TRUE
        AND lanes_assumed <= 3
        AND (
            bicycle_infrastructure_final IS TRUE
            OR highway NOT IN (
                'path',
                'bridleway',
                'footway',
                'pedestrian',
                'steps'
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
        AND maxspeed_assumed < 50 -- changed from =<
        AND lanes_assumed = 3 -- AND lanes_assumed < 4
        -- AND lanes_assumed > 2
    )
    OR (
        bicycle_class = 2
        AND bus_route IS TRUE
        AND maxspeed_assumed < 50
    )
    OR (
        (
            bicycle_class = 3
            OR bicycle_class IS NULL
        )
        AND bus_route IS TRUE
        AND maxspeed_assumed <= 30
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
        bicycle_class = 2
        AND bus_route IS TRUE
        AND maxspeed_assumed >= 50
    )
    OR (
        (
            bicycle_class = 3
            OR bicycle_class IS NULL
        )
        AND bus_route IS TRUE
        AND maxspeed_assumed > 30
        AND maxspeed_assumed <= 50
    )
    OR (
        (
            bicycle_class = 3
            OR bicycle_class IS NULL
        )
        AND maxspeed_assumed >= 30
        AND maxspeed_assumed <= 50
        AND lanes_assumed = 4
    )
    OR (
        (
            bicycle_class = 3
            OR bicycle_class IS NULL
        )
        AND maxspeed_assumed = 50
        AND lanes_assumed = 3
    )
    OR (
        (
            bicycle_class = 3
            OR bicycle_class IS NULL -- added obz
        )
        AND highway IN (
            'primary',
            'primary_link',
            'secondary',
            'secondary_link',
            'tertiary',
            'tertiary_link'
        )
        AND bicycle_infrastructure_final IS FALSE
        AND maxspeed_assumed >= 50
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
    )
    OR (
        (
            bicycle_class = 3
            OR bicycle_class IS NULL
        )
        AND bus_route IS TRUE
        AND maxspeed_assumed > 50
    );

-- *** EDGES CASES ***
UPDATE
    osm_road_edges
SET
    lts = 4
WHERE
    highway IN ('motorway_link')
    AND bicycle_class IS NULL;

UPDATE
    osm_road_edges
SET
    lts = 3
WHERE
    highway = 'unclassified'
    AND (
        bicycle_class IS NULL
        OR bicycle_class = 3
    )
    AND lanes_assumed < 3
    AND lts = 4 -- only decrease LTS value
;

UPDATE
    osm_road_edges
SET
    lts = 2
WHERE
    highway = 'residential'
    AND lanes_assumed < 4
    AND maxspeed_assumed <= 50
    AND lts = 3;

-- *** LTS 999 ***
UPDATE
    osm_road_edges
SET
    lts = 999
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

-- bicycle infrastructure missing an lts value
UPDATE
    osm_road_edges
SET
    lts = 1
WHERE
    highway IN ('pedestrian', 'living_street')
    AND cycling_allowed IS TRUE
    AND bicycle_infrastructure_final IS TRUE
    AND bicycle_class IS NOT NULL
    AND lts IS NULL;

UPDATE
    osm_road_edges
SET
    lts = 2
WHERE
    highway IN ('path')
    AND bicycle_infrastructure_final IS TRUE
    AND lts IS NULL
    AND bicycle_category = 'cyclelane';

DO $$
DECLARE
    bike_null INT;

BEGIN
    SELECT
        COUNT(*) INTO bike_null
    FROM
        osm_road_edges
    WHERE
        lts IS NULL
        AND bicycle_infrastructure_final IS TRUE
        AND bicycle_category <> 'crossing';

ASSERT bike_null = 0,
'Bike edges missing LTS value';

END $$;