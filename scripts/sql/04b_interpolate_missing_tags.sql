ALTER TABLE
    osm_road_edges
ADD
    COLUMN bicycle_surface_assumed VARCHAR DEFAULT NULL,
ADD
    COLUMN lit_assumed VARCHAR DEFAULT NULL,
ADD
    COLUMN speed_assumed VARCHAR DEFAULT NULL;

-- Limiting number of road segments with road type 'unknown'
CREATE VIEW unknown_roadtype AS (
    SELECT
        name,
        osmid,
        highway,
        geometry
    FROM
        osm_road_edges
    WHERE
        highway = 'unclassified'
);

CREATE VIEW known_roadtype AS (
    SELECT
        name,
        osmid,
        highway,
        geometry
    FROM
        osm_road_edges
    WHERE
        highway != 'unclassified'
        AND highway NOT IN ('cycleway', 'path', 'track')
);

UPDATE
    unknown_roadtype uk
SET
    highway = kr.highway
FROM
    known_roadtype kr
WHERE
    ST_Touches(uk.geometry, kr.geometry)
    AND uk.name = kr.name;

-- UPDATE unknown_roadtype uk SET highway = kr.highway FROM known_roadtype kr 
--     WHERE uk.name = kr.name AND uk.highway = 'unclassified';
DROP VIEW unknown_roadtype;

DROP VIEW known_roadtype;

-- SURFACE
-- Catch edges with both befæstet/ubefæstet due to simplification 
-- Surface from GeoDK is not assumed
UPDATE
    osm_road_edges
SET
    bicycle_surface_assumed = cycleway_surface;

-- TODO: supplement with geodk
-- Cycling surface is assumed paved if along a car street    
UPDATE
    osm_road_edges
SET
    bicycle_surface_assumed = 'paved'
WHERE
    highway IN (
        'trunk',
        'trunk_link',
        'tertiary',
        'tertiary_link',
        'secondary',
        'secondary_link',
        'living_street',
        'primary',
        'primary_link',
        'residential',
        --'service',
        'motorway',
        'motorway_link'
    )
    AND bicycle_surface_assumed IS NULL
    AND cycling_allowed = 'yes';

;

UPDATE
    osm_road_edges
SET
    bicycle_surface_assumed = 'paved'
WHERE
    along_street = True
    AND surface IS NULL;

-- UPDATE BASED ON URBAN AREAS
-- LIT
UPDATE
    osm_road_edges
SET
    lit_assumed = lit;

-- TODO: INVESTIGATE
UPDATE
    osm_road_edges
SET
    lit_assumed = 'yes'
WHERE
    highway IN (
        'trunk',
        'trunk_link',
        'tertiary',
        'tertiary_link',
        'secondary',
        'secondary_link',
        'living_street',
        'primary',
        'primary_link',
        --'residential',
        'motorway',
        'motorway_link'
    )
    AND lit_assumed IS NULL
    AND urban_area = 'yes';

-- TODO: INVESTIGATE
UPDATE
    osm_road_edges
SET
    lit_assumed = 'yes'
WHERE
    along_street = TRUE
    AND highway = 'cycleway'
    AND urban_area = 'yes'
    AND lit_assumed IS NULL;

-- is this safe to assume??
--UPDATE osm_road_edges SET lit_assumed = 'yes' WHERE along_street = 'true' AND urban = 'urban';
-- SPEED 
-- UPDATE osm_road_edges SET speed_as = speed;
-- UPDATE osm_road_edges WHERE speed_as IS NULL
--     SET speed_as
--         CASE
--             WHEN highway IN ('motorway','motorway_link',) THEN 130
--             WHEN highway IN ('residential') THEN 
--             WHEN highway IN ('trunk','trunk_link') THEN
--             WHEN highway IN ('living_street','bicycle_street') THEN
--         END
-- ;
--         ('trunk', 'trunk_link',
--         'tertiary',
--         'tertiary_link',
--         'secondary',
--         'secondary_link',
--         'living_street',
--         'primary',
--         'primary_link',
--         'residential',
--         'service')