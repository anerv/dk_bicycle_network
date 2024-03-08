-- close smaller gaps in bicycle infrastructure
ALTER TABLE
    osm_road_edges DROP COLUMN IF EXISTS bicycle_gap;

ALTER TABLE
    osm_road_edges
ADD
    COLUMN bicycle_gap VARCHAR DEFAULT NULL;

CREATE VIEW bicycle_nodes AS (
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
        bicycle_infrastructure_final IS TRUE
);

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
        'trunk_link'
    )
    AND bicycle NOT IN ('no', 'use_sidepath');

UPDATE
    potential_bicycle_gaps
SET
    along_street = TRUE,
    bicycle_gap = 'crossing',
    bicycle_protected = FALSE
WHERE
    highway IN ('footway', 'pedestrian');

UPDATE
    potential_bicycle_gaps
SET
    along_street = TRUE,
    bicycle_gap = 'cyclelane',
    bicycle_protected = FALSE
WHERE
    highway IN (
        'secondary',
        'service',
        'tertiary',
        'primary',
        'trunk',
        'residential',
        'unclassified',
        'track'
    );

UPDATE
    potential_bicycle_gaps
SET
    bicycle_protected = TRUE
WHERE
    highway IN ('path', 'bridleway');

UPDATE
    potential_bicycle_gaps
SET
    bicycle_gap = 'cycletrack'
WHERE
    highway IN ('path', 'bridleway')
    AND along_street IS TRUE;

UPDATE
    potential_bicycle_gaps
SET
    bicycle_gap = 'cycleway'
WHERE
    highway IN ('path', 'bridleway')
    AND along_street IS FALSE;

UPDATE
    osm_road_edges
SET
    bicycle_infrastructure_final = TRUE,
    cycling_allowed = TRUE
WHERE
    id IN (
        SELECT
            id
        FROM
            potential_bicycle_gaps
    );

UPDATE
    osm_road_edges o
SET
    bicycle_protected = g.bicycle_protected,
    bicycle_gap = g.bicycle_gap,
    along_street = g.along_street
FROM
    potential_bicycle_gaps g
WHERE
    o.id = g.id;

DROP VIEW IF EXISTS bicycle_nodes;

DROP TABLE IF EXISTS potential_bicycle_gaps;