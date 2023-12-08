-- *** STEP 1: PREPARE DATABASE AND INPUT DATA
-- PREPARE DATABASE
DROP SCHEMA IF EXISTS matching_geodk_osm CASCADE;

CREATE SCHEMA matching_geodk_osm;

DROP SCHEMA IF EXISTS matching_geodk_osm_no_bike CASCADE;

CREATE SCHEMA matching_geodk_osm_no_bike;

-- MERGE LINESTRINGS GEODK
SELECT
    min(objectid) AS id,
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
    min(id) AS id,
    bicycle_infrastructure,
    (
        st_dump(ST_LineMerge(st_union(ST_Force2D(geometry))))
    ) .geom AS geom INTO matching_geodk_osm._extract_osm
FROM
    osm_road_edges
WHERE
    highway NOT IN ('footway', 'bridleway')
GROUP BY
    id,
    bicycle_infrastructure;

-- -- MERGE LINESTRINGS OSM NO BIKE
-- SELECT
--     min(osm_id) AS id,
--     (
--         st_dump(ST_LineMerge(st_union(ST_Force2D(geometry))))
--     ).geom AS geom INTO matching_geodk_osm_no_bike._extract_osm
-- FROM
--     osm_roads
-- WHERE
--     bicycle_infrastructure IS FALSE
-- GROUP BY
--     osm_id,
--     bicycle_infrastructure;