-- CLASSIFY 
ALTER TABLE
    osm_roads
ADD
    COLUMN cycling_allowed BOOLEAN DEFAULT NULL,
ADD
    COLUMN car_traffic BOOLEAN DEFAULT NULL,
    --ADD COLUMN bike_separated VARCHAR DEFAULT NULL,
ADD
    COLUMN along_street VARCHAR DEFAULT NULL;

-- UPDATE osm_edges_simplified SET maxspeed = NULL WHERE maxspeed = 'unknown';
-- UPDATE osm_edges_simplified SET cycleway = NULL WHERE cycleway = 'unknown';
-- UPDATE osm_edges_simplified SET "cycleway:both" = NULL WHERE cycleway_both = 'unknown';
-- UPDATE osm_edges_simplified SET "cycleway:left" = NULL WHERE cycleway_left = 'unknown';
-- UPDATE osm_edges_simplified SET "cycleway:right" = NULL WHERE cycleway_right = 'unknown';
-- UPDATE osm_edges_simplified SET bicycle_road = NULL WHERE bicycle_road = 'unknown';
-- UPDATE osm_edges_simplified SET surface = NULL WHERE surface = 'unknown';
-- UPDATE osm_edges_simplified SET lit = NULL WHERE lit = 'unknown';
--Determining whether the segment of cycling infrastructure runs along a street or not
-- Along a street with car traffic
UPDATE
    osm_edges_simplified
SET
    along_street = 'false'
WHERE
    cycling_infra_new = 'yes'
    AND along_street IS NULL;

UPDATE
    osm_edges_simplified
SET
    along_street = 'true'
WHERE
    car_traffic = 'yes'
    AND cycling_infra_new = 'yes';

UPDATE
    osm_edges_simplified
SET
    along_street = 'true'
WHERE
    geodk_bike IS NOT NULL;

-- Capturing cycleways digitized as individual ways but still running parallel to a street
CREATE VIEW cycleways AS (
    SELECT
        name,
        highway,
        cycling_infrastructure,
        along_street
    FROM
        osm_edges_simplified
    WHERE
        highway = 'cycleway'
);

CREATE VIEW car_roads AS (
    SELECT
        name,
        highway,
        geometry
    FROM
        osm_edges_simplified
    WHERE
        car_traffic = 'yes'
) -- should it include service?
;

-- UPDATE cycleways c SET along_street = 'true'
--     FROM car_roads cr WHERE c.name = cr.name
-- ;
CREATE TABLE buffered_car_roads AS (
    SELECT
        (ST_Dump(geom)).geom
    FROM
        (
            SELECT
                ST_Union(ST_Buffer(geometry, 30)) AS geom
            FROM
                car_roads
        ) cr
);

CREATE INDEX buffer_geom_idx ON buffered_car_roads USING GIST (geom);

CREATE INDEX osm_edges_geom_idx ON osm_edges_simplified USING GIST (geometry);

CREATE TABLE intersecting_cycle_roads AS (
    SELECT
        o.edge_id,
        o.geometry
    FROM
        osm_edges_simplified o,
        buffered_car_roads br
    WHERE
        o.cycling_infra_new = 'yes'
        AND ST_Intersects(o.geometry, br.geom)
);

CREATE TABLE cycle_infra_points AS (
    SELECT
        edge_id,
        ST_Collect(
            ARRAY [ST_StartPoint(geometry), ST_Centroid(geometry), ST_EndPoint(geometry)]
        ) AS geometry
    FROM
        intersecting_cycle_roads
);

CREATE INDEX cycle_points_geom_idx ON cycle_infra_points USING GIST (geometry);

CREATE TABLE cycling_cars AS (
    SELECT
        c.edge_id,
        c.geometry
    FROM
        cycle_infra_points c,
        buffered_car_roads br
    WHERE
        ST_CoveredBy(c.geometry, br.geom)
);

UPDATE
    osm_edges_simplified o
SET
    along_street = 'true'
FROM
    cycling_cars c
WHERE
    o.edge_id = c.edge_id;

-- Interpolate missing tags
-- then matching 
-- then network!
-- classify nodes
-- analysis - is data cleaning done?