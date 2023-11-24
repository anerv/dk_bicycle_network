CREATE TABLE osm_roads AS (
    SELECT
        *
    FROM
        planet_osm_line
    WHERE
        highway IN (
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
            'trunk_link',
            'living_street',
            'busway',
            'primary_link',
            'motorway_link',
            'motorway',
            'unclassified'
        )
);

-- Drop irrelevant rows
DELETE FROM
    osm_roads
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
    osm_roads
WHERE
    access = 'private'
    AND boundary = 'security';

DELETE FROM
    osm_roads
WHERE
    construction IS NOT NULL;

DELETE FROM
    osm_roads
WHERE
    disused = 'yes';

-- Drop unneccesary columns
ALTER TABLE
    osm_roads DROP COLUMN IF EXISTS "admin_level",
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
    DROP COLUMN IF EXISTS "wood";

ALTER TABLE
    osm_roads RENAME COLUMN way TO geometry;

ALTER TABLE
    osm_roads
ALTER COLUMN
    geometry TYPE Geometry(LineString, 25832) USING ST_Transform(geometry, 25832);

CREATE INDEX roads_geom_idx ON osm_roads USING GIST (geometry);