-- Close smaller gaps in bicycle infrastructure
ALTER TABLE
    osm_road_edges DROP COLUMN IF EXISTS bicycle_gap;

ALTER TABLE
    osm_road_edges
ADD
    COLUMN bicycle_gap VARCHAR DEFAULT NULL;

-- Create a view to identify nodes with bicycle infrastructure
CREATE VIEW bicycle_nodes AS
SELECT
    source AS node
FROM
    osm_road_edges
WHERE
    bicycle_infrastructure_final IS TRUE
UNION
SELECT
    target AS node
FROM
    osm_road_edges
WHERE
    bicycle_infrastructure_final IS TRUE;

-- Create a table for potential bicycle gaps
CREATE TABLE potential_bicycle_gaps AS
SELECT
    *
FROM
    osm_road_edges
WHERE
    source IN (
        SELECT
            node
        FROM
            bicycle_nodes
    )
    AND target IN (
        SELECT
            node
        FROM
            bicycle_nodes
    )
    AND bicycle_infrastructure_final IS FALSE
    AND ST_length(geometry) < 15
    AND highway NOT IN (
        'motorway',
        'motorway_link',
        'primary_link',
        'secondary_link',
        'tertiary_link',
        'trunk_link',
        'steps'
    )
    AND bicycle NOT IN ('no', 'use_sidepath', 'separate');

-- Update the potential bicycle gaps table with the required values using a CASE expression
UPDATE
    potential_bicycle_gaps
SET
    along_street = TRUE,
    bicycle_protected = CASE
        WHEN highway IN ('path', 'bridleway') THEN TRUE
        ELSE FALSE
    END,
    bicycle_gap = CASE
        WHEN highway IN ('footway', 'pedestrian', 'steps') THEN 'crossing'
        WHEN highway IN (
            'secondary',
            'service',
            'tertiary',
            'primary',
            'trunk',
            'residential',
            'unclassified',
            'track'
        ) THEN 'cyclelane'
        WHEN highway IN ('path', 'bridleway')
        AND along_street IS TRUE THEN 'cycletrack'
        WHEN highway IN ('path', 'bridleway')
        AND along_street IS FALSE THEN 'cycleway'
    END;

-- Update osm_road_edges with the identified gaps
UPDATE
    osm_road_edges o
SET
    bicycle_infrastructure_final = TRUE,
    cycling_allowed = TRUE,
    bicycle_protected = g.bicycle_protected,
    bicycle_gap = g.bicycle_gap,
    along_street = g.along_street
FROM
    potential_bicycle_gaps g
WHERE
    o.id = g.id;

DROP VIEW IF EXISTS bicycle_nodes;

DROP TABLE IF EXISTS potential_bicycle_gaps;