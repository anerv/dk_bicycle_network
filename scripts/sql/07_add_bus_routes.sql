DROP TABLE IF EXISTS bus_stops;

CREATE TABLE bus_stops AS (
    SELECT
        osm_id AS node_id,
        ST_Transform(way, 25832) AS geometry
    FROM
        planet_osm_point
    WHERE
        highway = 'bus_stop'
);

CREATE INDEX bus_geom_idx ON bus_stops USING GIST (geometry);

WITH roads AS (
    SELECT
        id,
        geometry
    FROM
        osm_road_edges
    WHERE
        car_traffic IS TRUE
)
SELECT
    bus_stops.node_id,
    roads.id,
    roads.geometry,
    roads.dist
FROM
    bus_stops
    CROSS JOIN LATERAL (
        SELECT
            roads.id,
            roads.geometry,
            roads.geometry < -> bus_stops.geometry AS dist
        FROM
            roads
        ORDER BY
            dist
        LIMIT
            1
    ) roads;