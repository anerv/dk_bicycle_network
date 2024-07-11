-- UPDATE km and cost to match default cycling speed of 15 km/h
UPDATE
    osm_road_edges
SET
    km = ST_length(geometry) / 1000,
    kmh = 15;

UPDATE
    osm_road_edges
SET
    cost = km * kmh,
    reverse_cost = km * kmh;

ALTER TABLE
    osm_road_edges
ADD
    COLUMN IF NOT EXISTS lts_viz VARCHAR,
    -- ADD
    --     COLUMN IF NOT EXISTS bicycle_connector VARCHAR
ADD
    COLUMN IF NOT EXISTS bicycle_category_dk VARCHAR;

-- UPDATE
--     osm_road_edges
-- SET
--     bicycle_connector = lts
-- WHERE
--     highway NOT IN (
--         'motorway',
--         'trunk',
--         'motorway_link',
--         'trunk_link'
--     )
--     AND motorroad IS DISTINCT
-- FROM
--     'yes'
--     AND (
--         access NOT IN (
--             'no',
--             'private',
--             'foresty',
--             'agricultural',
--             'customers',
--             'residents',
--             'delivery',
--             'private;customers',
--             'permit',
--             'permit2'
--         )
--         OR access IS NULL
--     )
--     AND (
--         bicycle IN ('no', 'use_sidepath', 'separate')
--         OR cycleway IN ('use_sidepath', 'separate')
--         OR "cycleway:left" IN ('use_sidepath', 'separate')
--         OR "cycleway:right" IN ('use_sidepath', 'separate')
--         OR "cycleway:both" IN ('use_sidepath', 'separate')
--     );
UPDATE
    osm_road_edges
SET
    lts_viz = CASE
        WHEN (
            lts = 1
            AND cycling_allowed IS TRUE
        ) --AND all_access IS TRUE 
        THEN 'all_cyclists'
        WHEN (
            lts = 2
            AND cycling_allowed IS TRUE
        ) --AND all_access IS TRUE 
        THEN 'most_cyclists'
        WHEN (
            lts = 3
            AND cycling_allowed IS TRUE --AND all_access IS TRUE
        ) THEN 'confident_cyclists'
        WHEN (
            lts = 4
            AND cycling_allowed IS TRUE --AND all_access IS TRUE
        ) THEN 'very_confident_cyclists'
        WHEN (
            lts IN (1, 2, 3, 4)
            AND cycling_allowed IS FALSE
            AND all_access IS TRUE
        ) THEN 'no_cycling'
        WHEN (
            lts = 999
            AND all_access IS TRUE
        ) THEN 'pedestrian'
        WHEN (
            lts = 0
            AND all_access IS TRUE
        ) THEN 'paths_bike' --WHEN lts = 4 THEN 'no_cycling'
        WHEN all_access IS FALSE THEN 'no_access'
    END;

UPDATE
    osm_road_edges
SET
    lts_viz = 'dirt_road'
WHERE
    highway = 'track'
    AND cycling_allowed IS TRUE;

UPDATE
    osm_road_edges
SET
    bicycle_category_dk = CASE
        WHEN bicycle_category = 'shared_track' THEN 'delt sti langs vej'
        WHEN bicycle_category = 'cycleway' THEN 'cykelsti i eget trace'
        WHEN bicycle_category = 'cycleway_shared' THEN 'delt sti i eget trace'
        WHEN bicycle_category = 'cycletrack' THEN 'cykelsti langs vej'
        WHEN bicycle_category = 'cyclelane' THEN 'cykelbane'
        WHEN bicycle_category = 'shared_busway' THEN 'delt busbane'
        WHEN bicycle_category = 'cycle_living_street'
        AND (
            highway IN ('bicycle_road', 'cyclestreet', 'living_street')
            OR cyclestreet = 'yes'
            OR bicycle_road = 'yes'
        ) THEN 'cykelgade'
        WHEN bicycle_category = 'cycle_living_street'
        AND highway IN ('pedestrian')
        AND bicycle_infrastructure_final IS TRUE THEN 'gågade cykling tilladt'
        WHEN bicycle_category = 'crossing' THEN 'cykelbane i kryds'
        WHEN bicycle_category = 'shared_lane' THEN 'delt cykelbane'
    END;

DO $$
DECLARE
    bike_dk_count INT;

BEGIN
    SELECT
        COUNT(*) INTO bike_dk_count
    FROM
        osm_road_edges
    WHERE
        bicycle_category IS NOT NULL
        AND bicycle_category_dk IS NULL;

ASSERT bike_dk_count = 0,
'Edges missing bicycle category value in Danish';

END $$;

DO $$
DECLARE
    lts_viz_count INT;

BEGIN
    SELECT
        COUNT(*) INTO lts_viz_count
    FROM
        osm_road_edges
    WHERE
        lts IS NOT NULL
        AND lts_viz IS NULL;

ASSERT lts_viz_count = 0,
'Edges missing LTS viz value';

END $$;