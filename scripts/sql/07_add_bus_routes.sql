-- Drop unnecessary tables if they exist
DROP TABLE IF EXISTS bus_route_ways,
bus_roads,
bus_stops;

-- Update osm_road_edges: Drop and add bus_route column
ALTER TABLE
    osm_road_edges DROP COLUMN IF EXISTS bus_route,
ADD
    COLUMN bus_route BOOLEAN DEFAULT NULL;

-- Create a temporary table for bus_route_ways
CREATE TEMP TABLE bus_route_ways AS WITH route_ways AS (
    SELECT
        way_id,
        geom,
        unnest(rel_ids) AS rel_id
    FROM
        highways
    WHERE
        rel_ids IS NOT NULL
),
bus_routes AS (
    SELECT
        relation_id
    FROM
        routes
    WHERE
        route = 'bus'
)
SELECT
    rw.way_id,
    rw.geom
FROM
    route_ways rw
    JOIN bus_routes br ON rw.rel_id = br.relation_id;

-- Update osm_road_edges based on bus_route_ways
UPDATE
    osm_road_edges
SET
    bus_route = TRUE
WHERE
    osm_id IN (
        SELECT
            DISTINCT way_id
        FROM
            bus_route_ways
    );

-- Drop temporary tables
DROP TABLE IF EXISTS bus_route_ways,
bus_roads,
bus_stops;