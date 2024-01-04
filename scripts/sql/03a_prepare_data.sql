-- *** STEP 1: PREPARE DATABASE AND INPUT DATA
-- PREPARE DATABASE
DROP SCHEMA IF EXISTS matching_geodk_osm CASCADE;

CREATE SCHEMA matching_geodk_osm;

DROP SCHEMA IF EXISTS matching_geodk_osm_no_bike CASCADE;

CREATE SCHEMA matching_geodk_osm_no_bike;

-- MERGE LINESTRINGS GEODK
SELECT
    MIN(objectid) AS id,
    vejkategori,
    overflade,
    (
        st_dump(ST_LineMerge(st_union(ST_Force2D(geometry))))
    ) .geom AS geom INTO matching_geodk_osm._extract_geodk
FROM
    geodk_bike
GROUP BY
    vejkode,
    vejkategori,
    overflade;

-- MERGE LINESTRINGS OSM
SELECT
    MIN(id) AS id,
    bicycle_infrastructure,
    (
        st_dump(ST_LineMerge(st_union(ST_Force2D(geometry))))
    ) .geom AS geom INTO matching_geodk_osm._extract_osm
FROM
    osm_road_edges
WHERE
    highway NOT IN (
        'footway',
        'bridleway',
        'pedestrian',
        'motorway_link'
    )
GROUP BY
    id,
    bicycle_infrastructure;