-- TODO: update km
-- TODO: update cost (based on km and kmh)
-- TODO: update reverse cost
-- looking for edges that have been split!
ALTER TABLE
    osm_road_edges
ADD
    COLUMN edge_length NUMERICAL DEFAULT NULL;

UPDATE
    osm_road_edges
SET
    edge_length = ST_length(geometry);

UPDATE
    osm_road_edges
SET
    km = edge_length
WHERE
    km <> edge_length;

-- TODO: look at kmh - should match maxspeed assumed? use maxspeed assumed instead?
-- UPDATE
--     osm_road_edges
-- SET
--     cost = km * kmh;
-- UPDATE
--     osm_road_edges
-- SET
--     cost_reverse = ? ? ?;
SELECT
    id,
    osmid,
    x1,
    y1,
    x1,
    x2,
    source,
    target,
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
    lts,
    lit,
    maxspeed_assumed,
    lanes_assumed,
    bicycle_surface_assumed,
    centerline_assumed,
    urban,
    geometry
FROM
    osm_road_edges;