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
    osm_road_edges DROP COLUMN IF EXISTS lts_viz,
    DROP COLUMN IF EXISTS bicycle_category_dk;

ALTER TABLE
    osm_road_edges
ADD
    COLUMN lts_viz VARCHAR,
ADD
    COLUMN bicycle_category_dk VARCHAR;

UPDATE
    osm_road_edges
SET
    lts_viz = CASE
        WHEN lts = 1
        AND cycling_allowed IS TRUE
        AND all_access IS TRUE THEN 'all_cyclists'
        WHEN lts = 2
        AND cycling_allowed IS TRUE
        AND all_access IS TRUE THEN 'most_cyclists'
        WHEN lts = 3
        AND cycling_allowed IS TRUE
        AND all_access IS TRUE THEN 'confident_cyclists'
        WHEN lts = 4
        AND cycling_allowed IS TRUE
        AND all_access IS TRUE THEN 'very_confident_cyclists'
        WHEN lts IN (1, 2, 3, 4)
        AND cycling_allowed IS FALSE
        AND all_access IS TRUE THEN 'no_cycling'
        WHEN lts = 999
        AND all_access IS TRUE THEN 'pedestrian'
        WHEN lts = 0
        AND all_access IS TRUE THEN 'paths_bike' --WHEN lts = 4 THEN 'no_cycling'
        WHEN all_access IS FALSE THEN 'no_access'
    END;

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

DROP TABLE IF EXISTS osm_edges_export;

DROP TABLE IF EXISTS osm_nodes_export;

CREATE TABLE osm_edges_export AS (
    SELECT
        highway,
        "name",
        bicycle_category_dk,
        cycling_allowed,
        car_traffic,
        along_street,
        lit,
        cycleway_segregated,
        car_oneway,
        bike_oneway,
        bikeinfra_oneway,
        maxspeed_assumed AS maxspeed,
        lanes_assumed AS lanes,
        bicycle_surface_assumed AS surface,
        centerline_assumed AS centerline,
        urban,
        all_access,
        bus_route,
        bicycle_infrastructure AS bicycle_infrastructure_osm,
        bicycle_infrastructure_final,
        matched,
        geodk_category,
        bicycle_category,
        bicycle_class,
        bridge,
        tunnel,
        lts,
        lts_viz,
        municipality,
        id,
        osm_id,
        x1,
        y1,
        x2,
        y2,
        source,
        target,
        km,
        kmh,
        cost,
        reverse_cost,
        geometry
    FROM
        osm_road_edges
);

CREATE TABLE osm_nodes_export AS (
    SELECT
        id,
        osm_id,
        intersection_type,
        highway,
        crossing,
        node_degree,
        geometry
    FROM
        nodes
);