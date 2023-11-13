CREATE TABLE osm_roads AS (
    SELECT
        *
    from
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
    access in ('no');

-- private, private;custorms??
DELETE FROM
    osm_roads
WHERE
    access = 'private'
    and boundary = 'security';

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

-- Assign municipality to network
ALTER TABLE
    osm_roads
ADD
    COLUMN municipality VARCHAR DEFAULT NULL,
;

UPDATE
    osm_road o
SET
    municipality = m.navn
FROM
    muni_boundaries m
WHERE
    ST_Intersects(o.geometry, m.geometry);

-- Assign urban type to network
ALTER TABLE
    osm_roads
ADD
    COLUMN urban VARCHAR DEFAULT NULL,
;

UPDATE
    osm_road o
SET
    urban = u.navn
FROM
    urban_polygons_8 u
WHERE
    ST_Intersects(o.geometry, u.geometry);