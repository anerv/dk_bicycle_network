CREATE TABLE osm_roads AS (
    SELECT * from planet_osm_line WHERE highway IN ('cycleway'
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
        'unclassified')
    );


construction?
disused?

access NOT IN ('no','delivery') -- private, private;custorms??

-- drop admin level, amenity, area, horse   landuse railway wetland

-- mark bicycle infra

-- other classifications? e.g. simplify highway tags

-- then matching 

-- then network!