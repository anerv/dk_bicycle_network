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
        WHEN oneway = 'yes' THEN TRUE
        WHEN oneway = '-1' THEN TRUE
        ELSE FALSE
    END;

UPDATE
    osm_road_edges
SET
    bike_oneway =
    WHEN oneway IN ('yes', '-1')
    AND "oneway:bicycle" <> 'no' THEN TRUE
END;

UPDATE
    osm_road_edges
SET
    bikeinfra_oneway CASE
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
        ) THEN TRUE --
        -- bicycle infra roads where only oneway:bicycle is relevant
        WHEN (
            highway IN ('living_street')
            AND bicycle_infrastructure_final IS TRUE
            AND "oneway:bicycle" IN ('yes', '-1')
        ) THEN TRUE
        WHEN (
            (
                bicycle_road = 'yes'
                OR cyclestreet = 'yes'
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
            AND "oneway:bicycle" IN ('yes', '-1')
        ) THEN TRUE --
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
            AND "cycleway:right" NOT IN (
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
            AND "cycleway:left" NOT IN (
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
        ) THEN TRUE
    END;

-- HOW TO DEAL WITH GEODK? always assumed to be bi-directional - because we dont know
-- HOW TO DEAL WITH oneway:bicycle on non-bike infra?
-- one direction counts as one unit:
-- if a road is oneway infra length = length
-- if a road is not oneway infra length = length * 2
-- if a road has bike in one side or bike infra is one way --> infra length = length
-- if not one way or both sides --> infra length = length * 2