ALTER TABLE
    osm_road_edges DROP COLUMN IF EXISTS car_oneway,
    DROP COLUMN IF EXISTS bike_oneway,
    DROP COLUMN IF EXISTS bikeinfra_oneway;

ALTER TABLE
    osm_road_edges
ADD
    COLUMN car_oneway BOOLEAN DEFAULT NULL,
ADD
    COLUMN bike_oneway BOOLEAN DEFAULT NULL,
ADD
    COLUMN bikeinfra_oneway BOOLEAN DEFAULT NULL;

UPDATE
    osm_road_edges
SET
    car_oneway = CASE
        WHEN (
            oneway IN ('yes', '-1')
            AND car_traffic IS TRUE
        ) THEN TRUE
        WHEN (
            oneway NOT IN ('yes', '-1')
            AND car_traffic IS TRUE
        ) THEN FALSE
        WHEN (
            oneway IS NULL
            AND car_traffic IS TRUE
        ) THEN FALSE
        ELSE NULL
    END;

UPDATE
    osm_road_edges
SET
    bike_oneway = CASE
        -- a street with car traffic is oneway and there is no explicit information that this does not hold for bikes
        WHEN (
            oneway IN ('yes', '-1')
            AND cycling_allowed IS TRUE
            AND (
                "oneway:bicycle" <> 'no'
                OR "oneway:bicycle" IS NULL
            )
        ) THEN TRUE -- 
        -- explicit tagging of oneway for bikes
        WHEN (
            "oneway:bicycle" IN ('yes', '-1')
            AND cycling_allowed IS TRUE
        ) THEN TRUE --
        -- using the regular oneway for bikes for infrastructure where car traffic is not allowed
        WHEN (
            oneway IN ('yes', '-1')
            AND cycling_allowed IS TRUE
            AND car_traffic IS FALSE
        ) THEN TRUE --
        -- using either the regular oneway or bicycle oneway for no car traffic segments - if not explicitly tagged oneway it is set to false
        WHEN (
            (
                "oneway:bicycle" NOT IN ('yes', '-1')
                OR "oneway:bicycle" IS NULL
            )
            AND (
                oneway NOT IN ('yes', '-1')
                OR oneway IS NULL
            )
            AND cycling_allowed IS TRUE
            AND car_traffic IS FALSE
        ) THEN FALSE --
        -- using just bicycle oneway for car traffic segments - if not explicitly tagged bicycle oneway it is set to false
        WHEN (
            (
                "oneway:bicycle" NOT IN ('yes', '-1')
                OR "oneway:bicycle" IS NULL
            )
            AND cycling_allowed IS TRUE
            AND car_traffic IS TRUE
        ) THEN FALSE
        WHEN (
            bicycle_category_dk = 'cykelgade'
            AND (
                "oneway:bicycle" NOT IN ('yes', '-1')
                OR "oneway:bicycle" IS NULL
            )
        ) THEN FALSE
        ELSE NULL
    END;

UPDATE
    osm_road_edges
SET
    bikeinfra_oneway = CASE
        WHEN bike_oneway IS TRUE THEN TRUE --
        -- This catches any type where oneway bicycle explicitly is tagged
        WHEN (
            "oneway:bicycle" IN ('yes', '-1')
            AND bicycle_infrastructure_final IS TRUE
        ) THEN TRUE --
        -- Non car infra where both oneway or oneway:bicycle are relevant
        WHEN (
            highway IN (
                'cycleway',
                'path',
                'footway',
                'bridleway',
                'pedestrian'
            )
            AND bicycle_infrastructure_final IS TRUE
            AND oneway IN ('yes', '-1')
            OR "oneway:bicycle" IN ('yes', '-1')
        ) THEN TRUE
        WHEN (
            highway IN (
                'cycleway',
                'path',
                'footway',
                'bridleway',
                'pedestrian'
            )
            AND bicycle_infrastructure_final IS TRUE
            AND (
                oneway NOT IN ('yes', '-1')
                OR oneway IS NULL
            )
            AND (
                "oneway:bicycle" NOT IN ('yes', '-1')
                OR "oneway:bicycle" IS NULL
            )
        ) THEN FALSE --
        -- bicycle infra roads where only oneway:bicycle is relevant
        WHEN (
            highway IN ('living_street')
            AND bicycle_infrastructure_final IS TRUE
            AND "oneway:bicycle" IN ('yes', '-1')
        ) THEN TRUE
        WHEN (
            highway IN ('living_street')
            AND bicycle_infrastructure_final IS TRUE
            AND (
                "oneway:bicycle" NOT IN ('yes', '-1')
                OR "oneway:bicycle" IS NULL
            )
        ) THEN FALSE
        WHEN (
            (
                bicycle_road = 'yes'
                OR cyclestreet = 'yes'
            )
            AND bicycle_infrastructure_final IS TRUE
            AND "oneway:bicycle" IN ('yes', '-1')
        ) THEN TRUE
        WHEN (
            (
                bicycle_road = 'yes'
                OR cyclestreet = 'yes'
            )
            AND bicycle_infrastructure_final IS TRUE
            AND (
                "oneway:bicycle" NOT IN ('yes', '-1')
                OR "oneway:bicycle" IS NULL
            )
        ) THEN FALSE
        WHEN (
            cycleway IN (
                'track',
                'opposite_track',
                'share_sidewalk',
                'share_busway',
                'opposite_share_busway',
                'shared_lane',
                'opposite_lane',
                'crossing',
                'lane'
            )
            AND bicycle_infrastructure_final IS TRUE
            AND "oneway:bicycle" IN ('yes', '-1')
        ) THEN TRUE
        WHEN (
            cycleway IN (
                'track',
                'opposite_track',
                'share_sidewalk',
                'share_busway',
                'opposite_share_busway',
                'shared_lane',
                'opposite_lane',
                'crossing',
                'lane'
            )
            AND bicycle_infrastructure_final IS TRUE
            AND (
                "oneway:bicycle" NOT IN ('yes', '-1')
                OR "oneway:bicycle" IS NULL
            )
        ) THEN FALSE ----
        -- All infra only tagged in one side is assumed to be one way
        WHEN (
            "cycleway:left" IN (
                'track',
                'opposite_track',
                'share_sidewalk',
                'share_busway',
                'opposite_share_busway',
                'shared_lane',
                'opposite_lane',
                'crossing',
                'lane'
            )
            AND (
                "cycleway:right" NOT IN (
                    'track',
                    'opposite_track',
                    'share_sidewalk',
                    'share_busway',
                    'opposite_share_busway',
                    'shared_lane',
                    'opposite_lane',
                    'crossing',
                    'lane'
                )
                OR "cycleway:right" IS NULL
            )
            AND bicycle_infrastructure_final IS TRUE
        ) THEN TRUE
        WHEN (
            "cycleway:right" IN (
                'track',
                'opposite_track',
                'share_sidewalk',
                'share_busway',
                'opposite_share_busway',
                'shared_lane',
                'opposite_lane',
                'crossing',
                'lane'
            )
            AND (
                "cycleway:left" NOT IN (
                    'track',
                    'opposite_track',
                    'share_sidewalk',
                    'share_busway',
                    'opposite_share_busway',
                    'shared_lane',
                    'opposite_lane',
                    'crossing',
                    'lane'
                )
                OR "cycleway:left" IS NULL
            )
            AND bicycle_infrastructure_final IS TRUE
        ) THEN TRUE
        WHEN (
            "cycleway:right" IN (
                'track',
                'opposite_track',
                'share_sidewalk',
                'share_busway',
                'opposite_share_busway',
                'shared_lane',
                'opposite_lane',
                'crossing',
                'lane'
            )
            AND "cycleway:left" IN (
                'track',
                'opposite_track',
                'share_sidewalk',
                'share_busway',
                'opposite_share_busway',
                'shared_lane',
                'opposite_lane',
                'crossing',
                'lane'
            )
            AND bicycle_infrastructure_final IS TRUE
        ) THEN FALSE
        WHEN "cycleway:both" IN (
            'track',
            'opposite_track',
            'share_sidewalk',
            'share_busway',
            'opposite_share_busway',
            'shared_lane',
            'opposite_lane',
            'crossing',
            'lane'
        ) THEN FALSE
    END;

-- GeoDK always assumed to be two way due to lack of data on direction
UPDATE
    osm_road_edges
SET
    bikeinfra_oneway = FALSE
WHERE
    bikeinfra_oneway IS NULL
    AND bicycle_infrastructure_final IS TRUE -- bike infra only found in GeoDK
    AND bicycle_infrastructure IS FALSE;

-- HOW TO DEAL WITH GEODK? always assumed to be bi-directional - because we dont know
-- MAKE SURE THAT ALL BICYCLE INFRA HAS bikeinfra oneway filled out
-- one direction counts as one unit:
-- if a road is oneway infra length = length
-- if a road is not oneway infra length = length * 2
-- if a road has bike in one side or bike infra is one way --> infra length = length
-- if not one way or both sides --> infra length = length * 2
DO $$
DECLARE
    car_oneway_count INT;

BEGIN
    SELECT
        COUNT(*) INTO car_oneway_count
    FROM
        osm_road_edges
    WHERE
        car_oneway IS NULL
        AND car_traffic IS TRUE;

ASSERT car_oneway_count = 0,
'Car edges missing one way information';

END $$;

DO $$
DECLARE
    bike_oneway_count INT;

BEGIN
    SELECT
        COUNT(*) INTO bike_oneway_count
    FROM
        osm_road_edges
    WHERE
        bike_oneway IS NULL
        AND cycling_allowed IS TRUE;

ASSERT bike_oneway_count = 0,
'Bike edges missing one way information';

END $$;

DO $$
DECLARE
    bikeinfra_oneway_count INT;

BEGIN
    SELECT
        COUNT(*) INTO bikeinfra_oneway_count
    FROM
        osm_road_edges
    WHERE
        bicycle_infrastructure_final IS TRUE
        AND bikeinfra_oneway IS NULL;

ASSERT bikeinfra_oneway_count = 0,
'Bike infra edges missing bike infra one way information';

END $$;