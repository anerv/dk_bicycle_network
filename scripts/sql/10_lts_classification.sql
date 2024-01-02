-- not routing - not considering one-way?
-- but do use oneway for assumed lanes?
-- INTERSECTION LTS? (Identify unmarked intersections where a LTS XX crosses a road with a higher LTS)
ALTER TABLE
    osm_road_edges
ADD
    COLUMN lts INTEGER DEFAULT NULL;

UPDATE
    osm_road_edges
SET
    lts = 999
WHERE
    car_traffic IS FALSE
    and cycling_allowed IS FALSE;

-- TODO: check that this sets lts to 999 for footways, steps, etc.