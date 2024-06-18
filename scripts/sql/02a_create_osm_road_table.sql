DROP TABLE IF EXISTS osm_roads CASCADE;

DROP TABLE IF EXISTS osm_road_edges CASCADE;

CREATE TABLE osm_roads AS (
    SELECT
        *
    FROM
        planet_osm_line
    WHERE
        highway IS NOT NULL
);

ALTER TABLE
    osm_roads RENAME COLUMN way TO geometry;

ALTER TABLE
    dk_2po_4pgr DROP COLUMN IF EXISTS "clazz",
    DROP COLUMN IF EXISTS "osm_meta",
    DROP COLUMN IF EXISTS "flags",
    DROP COLUMN IF EXISTS "osm_name";

ALTER TABLE
    osm_roads RENAME COLUMN osm_id TO osm_id_road;

CREATE TABLE osm_road_edges AS (
    SELECT
        *
    FROM
        dk_2po_4pgr e
        LEFT JOIN osm_roads r ON e.osm_id = r.osm_id_road
);

ALTER TABLE
    osm_road_edges DROP COLUMN IF EXISTS "geometry";

ALTER TABLE
    osm_road_edges RENAME COLUMN geom_way TO geometry;

ALTER TABLE
    osm_road_edges
ALTER COLUMN
    geometry TYPE Geometry(LineString, 25832) USING ST_Transform(geometry, 25832);

CREATE INDEX edges_geom_idx ON osm_road_edges USING GIST (geometry);

DELETE FROM
    osm_road_edges
WHERE
    highway NOT IN (
        'cycleway',
        'footway',
        'services',
        'secondary',
        'tertiary',
        'secondary_link',
        'tertiary_link',
        'bridleway',
        'primary',
        'pedestrian',
        'residential',
        'track',
        'service',
        'path',
        'trunk',
        'trunk_link',
        'living_street',
        'busway',
        'primary_link',
        'motorway_link',
        'motorway',
        'unclassified',
        'steps'
    );

DELETE FROM
    osm_road_edges
WHERE
    highway = 'service'
    AND service = 'driveway';

--Drop irrelevant rows
DELETE FROM
    osm_road_edges
WHERE
    access IN ('no')
    AND (
        bicycle = 'no'
        OR bicycle IS NULL
    )
    AND (
        foot = 'no'
        OR foot IS NULL
    );

-- private, private;custorms??
DELETE FROM
    osm_road_edges
WHERE
    access = 'private'
    AND boundary = 'security';

DELETE FROM
    osm_road_edges
WHERE
    construction IS NOT NULL;

DELETE FROM
    osm_road_edges
WHERE
    disused = 'yes';

DELETE FROM
    osm_road_edges
WHERE
    osm_id_road IS NULL;

-- Drop unneccesary columns
ALTER TABLE
    osm_road_edges DROP COLUMN IF EXISTS "admin_level",
    DROP COLUMN IF EXISTS "amenity",
    DROP COLUMN IF EXISTS "area",
    DROP COLUMN IF EXISTS "boundary",
    DROP COLUMN IF EXISTS "harbour",
    DROP COLUMN IF EXISTS "horse",
    DROP COLUMN IF EXISTS "landuse",
    DROP COLUMN IF EXISTS "leisure",
    DROP COLUMN IF EXISTS "natural",
    DROP COLUMN IF EXISTS "noexit",
    DROP COLUMN IF EXISTS "operator",
    DROP COLUMN IF EXISTS "railway",
    DROP COLUMN IF EXISTS "shop",
    DROP COLUMN IF EXISTS "traffic_sign",
    DROP COLUMN IF EXISTS "water",
    DROP COLUMN IF EXISTS "waterway",
    DROP COLUMN IF EXISTS "wetland",
    DROP COLUMN IF EXISTS "construction",
    DROP COLUMN IF EXISTS "covered",
    DROP COLUMN IF EXISTS "disused",
    DROP COLUMN IF EXISTS "incline",
    DROP COLUMN IF EXISTS "ref",
    DROP COLUMN IF EXISTS "turn:lanes",
    DROP COLUMN IF EXISTS "turn:forward",
    DROP COLUMN IF EXISTS "turn:backward",
    DROP COLUMN IF EXISTS "way_area",
    DROP COLUMN IF EXISTS "z_order",
    DROP COLUMN IF EXISTS "public_transport",
    DROP COLUMN IF EXISTS "moped",
    DROP COLUMN IF EXISTS "wood",
    DROP COLUMN IF EXISTS "osm_id_road";