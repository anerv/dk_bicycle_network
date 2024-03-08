DROP TABLE IF EXISTS bus_route_ways;

DROP TABLE IF EXISTS bus_roads;

DROP TABLE IF EXISTS bus_stops;

ALTER TABLE
    osm_road_edges DROP COLUMN IF EXISTS bus_route;

ALTER TABLE
    osm_road_edges
ADD
    COLUMN bus_route BOOLEAN DEFAULT NULL;

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

-- CREATE TABLE bus_stops AS (
--     SELECT
--         osm_id AS node_id,
--         ST_Transform(way, 25832) AS geometry
--     FROM
--         planet_osm_point
--     WHERE
--         highway = 'bus_stop'
-- );
-- CREATE INDEX bus_geom_idx ON bus_stops USING GIST (geometry);
-- CREATE TABLE bus_roads AS WITH roads AS (
--     SELECT
--         id,
--         geometry
--     FROM
--         osm_road_edges
--     WHERE
--         car_traffic IS TRUE
-- )
-- SELECT
--     bus_stops.node_id,
--     bus_stops.geometry AS geom,
--     roads.id,
--     roads.geometry,
--     roads.dist
-- FROM
--     bus_stops
--     CROSS JOIN LATERAL (
--         SELECT
--             roads.id,
--             roads.geometry,
--             roads.geometry < -> bus_stops.geometry AS dist
--         FROM
--             roads
--         ORDER BY
--             dist
--         LIMIT
--             1
--     ) roads;
-- UPDATE
--     osm_road_edges
-- SET
--     bus_route = TRUE
-- WHERE
--     id IN (
--         SELECT
--             id
--         FROM
--             bus_roads
--         WHERE
--             dist <= 20
--     );
DROP TABLE IF EXISTS bus_route_ways;

DROP TABLE IF EXISTS bus_roads;

DROP TABLE IF EXISTS bus_stops;