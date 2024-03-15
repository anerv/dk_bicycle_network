ALTER TABLE
    osm_road_edges
ADD
    COLUMN car_oneway BOOLEAN DEFAULT NULL,
ADD
    COLUMN bike_oneway BOOLEAN DEFAULT NULL,
;

-- one direction counts as one unit:
-- if a road is oneway infra length = length
-- if a road is not oneway infra length = length * 2
-- if a road has bike in one side or bike infra is one way --> infra length = length
-- if not one way or both sides --> infra length = length * 2