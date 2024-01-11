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

CREATE VIEW osm_edges_export AS (
    SELECT
        id,
        osmid,
        x1,
        y1,
        x1,
        x2,
        source,
        target,
        km,
        kmh,
        cost,
        reverse_cost,
        highway,
        NAME,
        bicycle_infrastructure AS bicycle_infrastructure_osm,
        bicycle_infrastructure_final,
        matched,
        geodk_category,
        bicycle_category,
        bicycle_class,
        along_street,
        cycleway_shared,
        cycling_allowed,
        car_traffic,
        lit,
        maxspeed_assumed,
        lanes_assumed,
        bicycle_surface_assumed,
        centerline_assumed,
        urban,
        lts,
        geometry
    FROM
        osm_road_edges
);

CREATE VIEW osm_nodes_export AS (
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