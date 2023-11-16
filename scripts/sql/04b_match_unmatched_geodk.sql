--- ##### STEP 1 ######## ----
-- PREPARE DATABASE
DROP SCHEMA IF EXISTS matching_geodk_osm_no_bike CASCADE;

-- TODO: UPDATE EVERYWHERE
CREATE SCHEMA matching_geodk_osm_no_bike;

--- ##### STEP 2 ######## ----
-- ###### PREPARE GEOMETRIES ###########
--
-- MERGE LINESTRINGS GEODK
-- SELECT
--     min(objectid) AS id,
--     (
--         st_dump(ST_LineMerge(st_union(ST_Force2D(geometry))))
--     ).geom AS geom INTO matching_geodk_osm_no_bike._extract_geodk
-- FROM
--     geodk_bike
-- GROUP BY
--     vejkode,
--     vejkategori;
--
-- MERGE LINESTRINGS OSM
SELECT
    min(osm_id) AS id,
    (
        st_dump(ST_LineMerge(st_union(ST_Force2D(geometry))))
    ).geom AS geom INTO matching_geodk_osm_no_bike._extract_osm
FROM
    osm_roads
WHERE
    bicycle_infrastructure IS FALSE
GROUP BY
    osm_id,
    bicycle_infrastructure;

--- ##### STEP 3 ######## ----
-- ### CREATE SEGMENTS ##### ---
-- FIND UNMATCHED GEODK SEGMENTS
CREATE TABLE matching_geodk_osm_no_bike._segments_geodk AS
SELECT
    *
FROM
    matching_geodk_osm._segments_geodk geodk_segs
WHERE
    NOT EXISTS (
        SELECT
            *
        FROM
            matching_geodk_osm._matches_geodk geodk_matches
        WHERE
            geodk_segs.unique_seg_id = geodk_matches.geodk_seg_id -- FIX
    );

-- CREATE OSM SEGMENTS
WITH data(id, geom) AS (
    SELECT
        id,
        geom
    FROM
        matching_geodk_osm_no_bike._extract_osm
)
SELECT
    ROW_NUMBER () OVER () AS id,
    id AS id_osm,
    i,
    ST_LineSubstring(geom, startfrac, LEAST(endfrac, 1)) AS geom INTO matching_geodk_osm_no_bike._segments_osm
FROM
    (
        SELECT
            id,
            geom,
            ST_Length(geom) len,
            10 sublen
        FROM
            data
    ) AS d
    CROSS JOIN LATERAL (
        SELECT
            i,
            (sublen * i) / len AS startfrac,
            (sublen * (i + 1)) / len AS endfrac
        FROM
            generate_series(0, floor(len / sublen) :: integer) AS t(i)
        WHERE
            (sublen * i) / len <> 1.0
    ) AS d2;

-- CREATE UNIQUE SEGMENT ID OSM
ALTER TABLE
    matching_geodk_osm_no_bike._segments_osm
ADD
    COLUMN unique_seg_id VARCHAR;

ALTER TABLE
    matching_geodk_osm_no_bike._segments_osm
ADD
    COLUMN neighbor_seg_id VARCHAR;

UPDATE
    matching_geodk_osm_no_bike._segments_osm
SET
    unique_seg_id = CAST (id AS text) || '_' || CAST (i AS text);

UPDATE
    matching_geodk_osm_no_bike._segments_osm
SET
    neighbor_seg_id = CAST ((id -1) AS text) || '_' || CAST ((i -1) AS text);

DO $ $ DECLARE count_unique_seg_id INT;

BEGIN
SELECT
    COUNT(DISTINCT unique_seg_id) INTO count_unique_seg_id
FROM
    matching_geodk_osm_no_bike._segments_osm;

ASSERT count_unique_seg_id = (
    SELECT
        COUNT(*)
    FROM
        matching_geodk_osm_no_bike._segments_osm
),
'OSM seg IDS not unique';

END $ $;

-- MAKE SURE THAT OSM SEGMENTS ARE NOT TOO SHORT
DROP TABLE IF EXISTS matching_geodk_osm_no_bike.merged_osm_segments CASCADE;

DROP TABLE IF EXISTS matching_geodk_osm_no_bike.too_short_osm_segs CASCADE;

CREATE TABLE matching_geodk_osm_no_bike.merged_osm_segments (
    id_osm decimal,
    long_seg_id VARCHAR,
    short_seg_id VARCHAR,
    long_i VARCHAR,
    short_i VARCHAR,
    geom geometry
);

CREATE TABLE matching_geodk_osm_no_bike.too_short_osm_segs AS
SELECT
    *
FROM
    matching_geodk_osm_no_bike._segments_osm
WHERE
    ST_Length(geom) < 3;

CREATE INDEX idx_osm_short_segs_geometry ON matching_geodk_osm_no_bike.too_short_osm_segs USING gist(geom);

WITH joined_data AS (
    SELECT
        short_segs.id_osm AS id_osm,
        neighbor_segs.unique_seg_id AS long_seg_id,
        short_segs.unique_seg_id AS short_seg_id,
        neighbor_segs.i AS long_i,
        short_segs.i AS short_i,
        ST_Collect(short_segs.geom, neighbor_segs.geom) AS geom
    FROM
        matching_geodk_osm_no_bike.too_short_osm_segs short_segs
        JOIN matching_geodk_osm_no_bike._segments_osm neighbor_segs ON short_segs.neighbor_seg_id = neighbor_segs.unique_seg_id
)
INSERT INTO
    matching_geodk_osm_no_bike.merged_osm_segments
SELECT
    *
FROM
    joined_data;

-- UPDATE GEOMETRIES IN OSM SEGMENTS
WITH joined_data AS (
    SELECT
        merged.geom AS new_geom,
        osm_segs.unique_seg_id AS seg_id
    FROM
        matching_geodk_osm_no_bike._segments_osm osm_segs
        JOIN matching_geodk_osm_no_bike.merged_osm_segments merged ON osm_segs.unique_seg_id = merged.long_seg_id
)
UPDATE
    matching_geodk_osm_no_bike._segments_osm
SET
    geom = new_geom
FROM
    joined_data
WHERE
    unique_seg_id = joined_data.seg_id;

-- DELETE TOO SHORT OSM SEGMENTS
DELETE FROM
    matching_geodk_osm_no_bike._segments_osm osm_segs USING matching_geodk_osm_no_bike.too_short_osm_segs too_short
WHERE
    osm_segs.unique_seg_id = too_short.unique_seg_id;

CREATE INDEX idx_segments_osm_geometry ON matching_geodk_osm_no_bike._segments_osm USING gist(geom);

--- ##### STEP 4 ######## ----
-- ### Find candidates ##### ---
--- Calculating angle and hausdorf distance for segments within buffer distance
-- Copies a geometry for each potential match
-- Two geometry columns - one for OSM candidates and one for GeoDK
SELECT
    id_geodk,
    id_osm,
    geodk_seg_id,
    osm_seg_id,
    angle,
    CASE
        WHEN angle > 270 THEN 360 - angle
        WHEN angle > 180 THEN angle -180
        WHEN angle > 90 THEN 180 - angle
        ELSE angle
    END AS angle_red,
    hausdorffdist,
    geodk_seg_geom,
    osm_seg_geom INTO matching_geodk_osm_no_bike._candidates
FROM
    (
        SELECT
            segments_geodk.id_geodk AS id_geodk,
            segments_osm.id_osm AS id_osm,
            segments_geodk.id AS geodk_seg_id,
            segments_osm.id AS osm_seg_id,
            degrees(
                ST_Angle(
                    st_asText(segments_geodk.geom),
                    st_asText(segments_osm.geom)
                )
            ) AS angle,
            ST_HausdorffDistance(segments_geodk.geom, segments_osm.geom) AS hausdorffdist,
            segments_geodk.geom AS geodk_seg_geom,
            segments_osm.geom AS osm_seg_geom
        FROM
            matching_geodk_osm_no_bike._segments_geodk AS segments_geodk
            JOIN matching_geodk_osm_no_bike._segments_osm AS segments_osm ON ST_Intersects(
                segments_geodk.geom,
                ST_Buffer(segments_osm.geom, 15)
            )
    ) AS a;

-- Find potential matches - i.e. within thresholds - Using OSM gemetries
SELECT
    _candidates.id_geodk,
    _candidates.id_osm,
    _candidates.geodk_seg_id,
    _candidates.osm_seg_id,
    _candidates.angle,
    _candidates.angle_red,
    _candidates.hausdorffdist,
    _candidates.osm_seg_geom AS geom INTO matching_geodk_osm_no_bike._matches_osm
FROM
    matching_geodk_osm_no_bike._candidates AS _candidates
    JOIN (
        SELECT
            osm_seg_id,
            min(hausdorffdist) AS mindist
        FROM
            matching_geodk_osm_no_bike._candidates
        WHERE
            angle_red < 30
            AND hausdorffdist < 17
        GROUP BY
            osm_seg_id
    ) AS a ON a.osm_seg_id = _candidates.osm_seg_id
    AND mindist = _candidates.hausdorffdist;

CREATE INDEX idx_matches_osm_geometry ON matching_geodk_osm_no_bike._matches_osm USING gist(geom);

-- Find potential matches - i.e. within thresholds - Using GeoDK gemetries
SELECT
    _candidates.id_geodk,
    _candidates.id_osm,
    _candidates.geodk_seg_id,
    _candidates.osm_seg_id,
    _candidates.angle,
    _candidates.angle_red,
    _candidates.hausdorffdist,
    _candidates.geodk_seg_geom AS geom INTO matching_geodk_osm_no_bike._matches_geodk
FROM
    matching_geodk_osm_no_bike._candidates AS _candidates
    JOIN (
        SELECT
            geodk_seg_id,
            min(hausdorffdist) AS mindist
        FROM
            matching_geodk_osm_no_bike._candidates
        WHERE
            angle_red < 30
            AND hausdorffdist < 17
        GROUP BY
            geodk_seg_id
    ) AS a ON a.geodk_seg_id = _candidates.geodk_seg_id
    AND mindist = _candidates.hausdorffdist;

CREATE INDEX idx_matches_geodk_geometry ON matching_geodk_osm_no_bike._matches_geodk USING gist(geom);

-- Find unmatched GeoDK segments and match to non-OSM bicycle infra
-- evaluate outcome