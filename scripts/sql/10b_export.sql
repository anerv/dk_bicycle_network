-- TODO: update km
-- TODO: update cost (based on km and kmh)
-- TODO: update reverse cost
-- looking for edges that have been split!
ALTER TABLE
    osm_road_edges
ADD
    COLUMN LENGTH NUMERICAL DEFAULT NULL;

UPDATE
    osm_road_edges
SET
    LENGTH = ST_length(geometry);

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
    geometry
FROM
    osm_road_edges;