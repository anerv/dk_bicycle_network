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
        bikeinfra_both_sides,
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
        bicycle_protected,
        bicycle_infrastructure_separate,
        bicycle,
        --bicycle_connector,
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