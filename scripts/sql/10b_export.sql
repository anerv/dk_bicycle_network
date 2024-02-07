-- UPDATE km and cost to match default cycling speed of 15 km/h
UPDATE
    osm_road_edges
SET
    km = ST_length(geometry),
    kmh = 15;

UPDATE
    osm_road_edges
SET
    cost = km * kmh,
    reverse_cost = km * kmh;

ALTER TABLE
    osm_road_edges
ADD
    COLUMN lts_viz VARCHAR;

UPDATE
    osm_road_edges
SET
    lts_viz = CASE
        WHEN lts = 1
        AND cycling_allowed IS TRUE THEN 'all_cyclists'
        WHEN lts = 2
        AND cycling_allowed IS TRUE THEN 'most_cyclists'
        WHEN lts = 3
        AND cycling_allowed IS TRUE THEN 'confident_cyclists'
        WHEN lts IN (1, 2, 3)
        AND cycling_allowed IS FALSE THEN 'no_cycling'
        WHEN lts = 999 THEN 'pedestrian'
        WHEN lts = 0 THEN 'paths_bike'
        WHEN lts = 4 THEN 'no_cycling'
    END;

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

DROP MATERIALIZED VIEW IF EXISTS osm_edges_export;

DROP MATERIALIZED VIEW IF EXISTS osm_nodes_export;

CREATE MATERIALIZED VIEW osm_edges_export AS (
    SELECT
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
        highway,
        "name",
        bicycle_infrastructure AS bicycle_infrastructure_osm,
        bicycle_infrastructure_final,
        matched,
        geodk_category,
        bicycle_category,
        bicycle_class,
        along_street,
        cycleway_segregated,
        cycling_allowed,
        car_traffic,
        lit,
        maxspeed_assumed,
        lanes_assumed,
        bicycle_surface_assumed,
        centerline_assumed,
        urban,
        lts,
        lts_viz,
        geometry
    FROM
        osm_road_edges
);

CREATE MATERIALIZED VIEW osm_nodes_export AS (
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