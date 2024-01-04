ALTER TABLE
    osm_road_edges
ADD
    COLUMN lts INTEGER DEFAULT NULL;

UPDATE
    osm_road_edges
SET
    lts = 999
WHERE
    car_traffic IS FALSE
    AND cycling_allowed IS FALSE;

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
        WHEN bicycle_category = 'cyclestreet' THEN 3
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
    lts = 2
WHERE
    (
        bicycle_class = 2
        AND maxspeed_assumed = < 40
    )
    OR (
        bicycle_class = 2
        AND (
            centerline_assumed IS TRUE
            AND (
                lanes_assumed = < 4
                AND oneway NOT IN ('yes', 'True', 'true', '1')
                OR (
                    lanes_assumed = < 2
                    AND oneway IN ('yes', 'True', 'true', '1')
                )
            )
        )
    );

UPDATE
    osm_road_edges
SET
    lts = 2
WHERE
    bicycle_class = 3
    AND (
        centerline_assumed IS TRUE
        AND maxspeed_assumed = < 50
        AND lanes_assumed = < 3
    )
    OR (
        centerline_assumed IS FALSE
        AND maxspeed_assumed = < 40
        AND lanes_assumed = < 2
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
    lts = 3
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
                lanes_assumed = < 4
                OR (
                    lanes_assumed = < 2
                    AND oneway IN ('yes', 'True', 'true', '1')
                )
            )
        )
    );

UPDATE
    osm_road_edges
SET
    lts = 3
WHERE
    bicycle_class = 3
    AND (
        centerline_assumed IS FALSE
        AND (
            assumed_lanes = < 3
            OR maxspeed_assumed = < 50
        )
    )
    OR (
        centerline_assumed IS TRUE
        AND (
            assumed_lanes = < 4
            OR maxspeed_assumed = < 70
        )
    );

-- *** LTS 4 ***
-- If bicycle category 2, speed of 70 km or more or two or more lanes per direction
-- If bicycle category 3, all roads with a speed of 60 or more or four or more lanes in total
--
UPDATE
    osm_road_edges
SET
    lts = 4
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
    lts = 4
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
    lts = 1
WHERE
    bicycle_class = 1
    AND bicycle_infrastructure_final = TRUE
    AND surface_assumed NOT IN ('gravel', 'grass');

-- *** LTS '5' WHERE cycling is not allowed but car traffic is **
UPDATE
    osm_road_edges
SET
    lts = 5
WHERE
    cycling_allowed IS FALSE
    AND car_traffic IS TRUE;

DO $$
DECLARE
    lts_null INT;

BEGIN
    SELECT
        COUNT(*) INTO lts_null
    FROM
        osm_road_edges
    WHERE
        lts IS NULL
        AND car_traffic IS TRUE
        OR (
            cycling_allowed IS TRUE
            AND surface_assumed NOT IN ('gravel', 'grass')
        );

ASSERT bike_class_null = 0,
'Edges missing LTS value';