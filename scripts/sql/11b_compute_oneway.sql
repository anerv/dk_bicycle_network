ALTER TABLE
    osm_road_edges DROP COLUMN IF EXISTS car_oneway,
    DROP COLUMN IF EXISTS bike_oneway,
    DROP COLUMN IF EXISTS bikeinfra_both_sides;

ALTER TABLE
    osm_road_edges
ADD
    COLUMN car_oneway BOOLEAN DEFAULT NULL,
ADD
    COLUMN bike_oneway BOOLEAN DEFAULT NULL,
ADD
    COLUMN bikeinfra_both_sides BOOLEAN DEFAULT NULL;

DROP INDEX IF EXISTS osm_road_edges_id_idx,
osm_road_edges_source_idx,
osm_road_edges_target_idx;

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
            bicycle_category = 'cycle_living_street'
            AND (
                highway IN ('bicycle_road', 'cyclestreet', 'living_street')
                OR cyclestreet = 'yes'
                OR bicycle_road = 'yes'
            )
            AND (
                "oneway:bicycle" NOT IN ('yes', '-1 ')
                OR "oneway:bicycle" IS NULL
            )
        ) THEN FALSE
        ELSE NULL
    END;

UPDATE
    osm_road_edges
SET
    bikeinfra_both_sides = CASE
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
            AND (
                "oneway:bicycle" NOT IN ('yes', '-1')
                OR "oneway:bicycle" IS NULL
            )
        ) THEN TRUE ----
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
        ) THEN FALSE
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
        ) THEN FALSE
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
        ) THEN TRUE
        WHEN (
            geodk_both_sides IS TRUE
            AND bicycle_infrastructure_final IS TRUE
        ) THEN TRUE
        ELSE FALSE
    END;

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
'Car edges missing one way information ';

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
'Bike edges missing one way information ';

END $$;

DO $$
DECLARE
    bikeinfra_side_count INT;

BEGIN
    SELECT
        COUNT(*) INTO bikeinfra_side_count
    FROM
        osm_road_edges
    WHERE
        bicycle_infrastructure_final IS TRUE
        AND bikeinfra_both_sides IS NULL;

ASSERT bikeinfra_side_count = 0,
'Bike infra edges missing information on side count!';

END $$;