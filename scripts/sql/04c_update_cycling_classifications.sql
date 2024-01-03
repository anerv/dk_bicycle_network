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

ALTER TABLE
    osm_road_edges
ADD
    COLUMN bicycle_category VARCHAR DEFAULT NULL;

-- cyclestreet / cycleway / cycletrack / cyclelane / crossing / shared_track / shared_lane / shared_busway
UPDATE
    osm_road_edges
SET
    bicycle_category = CASE
        WHEN (
            bicycle_infrastructure_final IS TRUE
            AND geodk_category = 'Cykelsti langs vej'
        ) THEN 'cycletrack'
        WHEN (
            bicycle_infrastructure_final IS TRUE
            AND geodk_category = 'Cykelbane langs vej'
        ) THEN 'cyclelane'
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
        WHEN (
            cycleway IN ('crossing')
            OR "cycleway:left" IN ('crossing')
            OR "cycleway:right" IN ('crossing')
            OR "cycleway:both" IN ('crossing')
        ) THEN 'crossing'
        WHEN (
            cycleway IN ('share_sidewalk')
            OR "cycleway:left" IN ('share_sidewalk')
            OR "cycleway:right" IN ('share_sidewalk')
            OR "cycleway:both" IN ('share_sidewalk')
        ) THEN 'shared_track'
        WHEN (
            cycleway IN ('shared_lane')
            OR "cycleway:left" IN ('shared_lane')
            OR "cycleway:right" IN ('shared_lane')
            OR "cycleway:both" IN ('shared_lane')
        ) THEN 'shared_lane'
        WHEN (
            cycleway IN ('share_busway')
            OR "cycleway:left" IN ('share_busway')
            OR "cycleway:right" IN ('share_busway')
            OR "cycleway:both" IN ('share_busway')
        ) THEN 'shared_busway'
        WHEN (
            cycleway IN ('lane', 'opposite_lane')
            OR "cycleway:left" IN ('lane', 'opposite_lane')
            OR "cycleway:right" IN ('lane', 'opposite_lane')
            OR "cycleway:both" IN ('lane', 'opposite_lane')
        ) THEN 'cyclelane'
        WHEN (
            cycleway IN ('track', 'opposite_track')
            OR "cycleway:left" IN ('track', 'opposite_track')
            OR "cycleway:right" IN ('track', 'opposite_track')
            OR "cycleway:both" IN ('track', 'opposite_track')
        ) THEN 'cycletrack'
        WHEN (
            highway IN ('bicycle_road', 'cyclestreet', 'living_street')
        ) THEN 'cyclestreet'
        WHEN (
            cyclestreet = 'yes'
            OR bicycle_road = 'yes'
        ) THEN 'cyclestreet'
        WHEN (
            highway IN ('track', 'path')
            AND bicycle_infrastructure_final IS TRUE
        ) THEN 'cycleway'
        WHEN (
            highway = 'cycleway'
            AND along_street IS FALSE
        ) THEN 'cycleway'
        WHEN (
            highway = 'cycleway'
            AND along_street IS TRUE
        ) THEN 'cycletrack'
        ELSE bicycle_category
    END;

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