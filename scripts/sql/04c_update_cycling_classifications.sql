-- CREATE COLUMN WITH SIMPLE BICYCLE INFRA TYPE
ALTER TABLE
    osm_road_edges DROP COLUMN IF EXISTS bicycle_category,
    DROP COLUMN IF EXISTS cycleway_segregated;

ALTER TABLE
    osm_road_edges
ADD
    COLUMN IF NOT EXISTS bicycle_category VARCHAR DEFAULT NULL,
ADD
    COLUMN IF NOT EXISTS cycleway_segregated BOOLEAN DEFAULT NULL;

-- UPDATE PROTECTED CLASSIFICATION FOR UNCLASSIFIED BICYCLE INFRA
UPDATE
    osm_road_edges
SET
    bicycle_protected = TRUE
WHERE
    bicycle_infrastructure_final IS TRUE
    AND bicycle_protected IS NULL
    AND geodk_category = 'Cykelsti langs vej';

UPDATE
    osm_road_edges
SET
    bicycle_protected = FALSE
WHERE
    bicycle_infrastructure_final IS TRUE
    AND bicycle_protected IS NULL
    AND geodk_category = 'Cykelbane langs vej';

DO $$
DECLARE
    count_protection_null INT;

BEGIN
    SELECT
        COUNT(*) INTO count_protection_null
    FROM
        osm_road_edges
    WHERE
        bicycle_infrastructure_final IS TRUE
        AND bicycle_protected IS NULL;

ASSERT count_protection_null = 0,
'Edges missing protection classification';

END $$;

-- cycle_living_street / cycleway / 'cycleway_shared' / cycletrack / cyclelane / crossing / shared_track / shared_lane / shared_busway
UPDATE
    osm_road_edges
SET
    bicycle_category = CASE
        WHEN (
            bicycle_infrastructure_final IS TRUE
            AND highway = 'cycleway'
            AND along_street IS FALSE
            AND (
                foot NOT IN ('yes', 'designated', 'permissive')
                OR foot IS NULL
                OR segregated = 'yes'
            )
        ) THEN 'cycleway'
        WHEN (
            bicycle_infrastructure_final IS TRUE
            AND highway = 'cycleway'
            AND along_street IS FALSE
            AND foot IN ('yes', 'designated', 'permissive')
            AND (
                segregated = 'no'
                OR segregated IS NULL
            )
        ) THEN 'cycleway_shared' -- WHEN (
        --     bicycle_infrastructure_final IS TRUE
        --     AND highway = 'cycleway'
        --     AND along_street IS FALSE
        -- ) THEN 'cycleway'
        WHEN (
            bicycle_infrastructure_final IS TRUE
            AND highway = 'cycleway'
            AND along_street IS TRUE
        ) THEN 'cycletrack'
        WHEN (
            bicycle_infrastructure_final IS TRUE
            AND (
                cycleway IN ('crossing')
                OR "cycleway:left" IN ('crossing')
                OR "cycleway:right" IN ('crossing')
                OR "cycleway:both" IN ('crossing')
            )
        ) THEN 'crossing'
        WHEN (
            bicycle_infrastructure_final IS TRUE
            AND (
                cycleway IN ('track', 'opposite_track')
                OR "cycleway:left" IN ('track', 'opposite_track')
                OR "cycleway:right" IN ('track', 'opposite_track')
                OR "cycleway:both" IN ('track', 'opposite_track')
            )
        ) THEN 'cycletrack'
        WHEN (
            bicycle_infrastructure_final IS TRUE
            AND (
                cycleway IN ('lane', 'opposite_lane')
                OR "cycleway:left" IN ('lane', 'opposite_lane')
                OR "cycleway:right" IN ('lane', 'opposite_lane')
                OR "cycleway:both" IN ('lane', 'opposite_lane')
            )
        ) THEN 'cyclelane'
        WHEN (
            bicycle_infrastructure_final IS TRUE
            AND (
                cycleway IN ('share_sidewalk')
                OR "cycleway:left" IN ('share_sidewalk')
                OR "cycleway:right" IN ('share_sidewalk')
                OR "cycleway:both" IN ('share_sidewalk')
            )
        ) THEN 'shared_track'
        WHEN (
            bicycle_infrastructure_final IS TRUE
            AND (
                cycleway IN ('shared_lane')
                OR "cycleway:left" IN ('shared_lane')
                OR "cycleway:right" IN ('shared_lane')
                OR "cycleway:both" IN ('shared_lane')
            )
        ) THEN 'shared_lane'
        WHEN (
            bicycle_infrastructure_final IS TRUE
            AND (
                cycleway IN ('share_busway')
                OR "cycleway:left" IN ('share_busway', 'opposite_share_busway')
                OR "cycleway:right" IN ('share_busway', 'opposite_share_busway')
                OR "cycleway:both" IN ('share_busway', 'opposite_share_busway')
            )
        ) THEN 'shared_busway'
        WHEN (
            bicycle_infrastructure_final IS TRUE
            AND geodk_category = 'Cykelsti langs vej'
        ) THEN 'cycletrack'
        WHEN (
            bicycle_infrastructure_final IS TRUE
            AND geodk_category = 'Cykelbane langs vej'
        ) THEN 'cyclelane'
        WHEN (
            highway IN (
                'path',
                'bridleway',
                'footway'
            )
            AND bicycle_infrastructure_final IS TRUE
        ) THEN 'cycleway_shared'
        WHEN (
            bicycle_infrastructure_final IS TRUE
            AND highway IN (
                'bicycle_road',
                'cyclestreet',
                'living_street',
                'pedestrian'
            )
        ) THEN 'cycle_living_street'
        WHEN (
            bicycle_infrastructure_final IS TRUE
            AND cyclestreet = 'yes'
            OR bicycle_road = 'yes'
        ) THEN 'cycle_living_street'
        WHEN (
            bicycle_infrastructure_final IS TRUE
            AND bicycle_gap = 'cycletrack'
        ) THEN 'cycletrack'
        WHEN (
            bicycle_infrastructure_final IS TRUE
            AND bicycle_gap = 'cyclelane'
        ) THEN 'cyclelane'
        WHEN (
            bicycle_infrastructure_final IS TRUE
            AND bicycle_gap = 'cycleway'
        ) THEN 'cycleway'
        WHEN (
            bicycle_infrastructure_final IS TRUE
            AND bicycle_gap = 'crossing'
        ) THEN 'crossing'
        ELSE bicycle_category
    END;

UPDATE
    osm_road_edges
SET
    cycleway_segregated = TRUE
WHERE
    (
        highway IN (
            'pedestrian',
            'living_street',
            'footway',
            'bridleway',
            'path'
        )
        AND foot <> 'no'
        AND segregated <> 'no'
    )
    OR bicycle_category = 'shared_track';

DO $$
DECLARE
    bike_category_null INT;

BEGIN
    SELECT
        COUNT(*) INTO bike_category_null
    FROM
        osm_road_edges
    WHERE
        bicycle_infrastructure_final IS TRUE
        AND bicycle_category IS NULL;

ASSERT bike_category_null = 0,
'Edges missing bicycle category';

END $$;

DO $$
DECLARE
    bike_category_ex INT;

BEGIN
    SELECT
        COUNT(*) INTO bike_category_ex
    FROM
        osm_road_edges
    WHERE
        bicycle_infrastructure_final IS FALSE
        AND bicycle_category IS NOT NULL;

ASSERT bike_category_ex = 0,
'Too many edges with bicycle category';

END $$;