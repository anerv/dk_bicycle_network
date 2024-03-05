CREATE TABLE bus_route_ways AS WITH route_ways AS (
    SELECT
        *
    FROM
        highways
    WHERE
        rel_ids IS NOT NULL
),
bus_routes AS (
    SELECT
        relation_id,
        route,
        NAME,
        network
    FROM
        routes
    WHERE
        route = 'bus'
)
SELECT
    *
FROM
    (
        SELECT
            way_id,
            geom,
            unnest(rel_ids) rel_id
        FROM
            route_ways
    ) AS rw
    JOIN bus_routes AS br ON rw.rel_id = br.relation_id;

ALTER TABLE
    osm_road_edges
ADD
    COLUMN bus_route BOOLEAN DEFAULT NULL;

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

DROP TABLE IF EXISTS bus_route_ways;