--- ##### STEP 1 ######## ----
-- PREPARE DATABASE
DROP SCHEMA IF EXISTS matching_geodk_osm CASCADE;

CREATE SCHEMA matching_geodk_osm;

--- ##### STEP 2 ######## ----
-- ###### PREPARE GEOMETRIES ###########
--
-- MERGE LINESTRINGS GEODK
SELECT
    min(objectid) AS id,
    (
        st_dump(ST_LineMerge(st_union(ST_Force2D(geometry))))
    ).geom AS geom INTO matching_geodk_osm._extract_geodk
FROM
    geodk_bike
GROUP BY
    vejkode,
    vejkategori;

-- MERGE LINESTRINGS OSM
SELECT
    min(osm_id) AS id,
    (
        st_dump(ST_LineMerge(st_union(ST_Force2D(geometry))))
    ).geom AS geom INTO matching_geodk_osm._extract_osm
FROM
    osm_roads
WHERE
    bicycle_infrastructure IS TRUE
GROUP BY
    osm_id,
    bicycle_infrastructure;

--- ##### STEP 3 ######## ----
-- ### CREATE SEGMENTS ##### ---
--
-- CREATE GEODK SEGMENTS
WITH data(id, geom) AS (
    SELECT
        id,
        geom
    FROM
        matching_geodk_osm._extract_geodk
)
SELECT
    ROW_NUMBER () OVER () AS id,
    id AS id_geodk,
    i,
    ST_LineSubstring(geom, startfrac, LEAST(endfrac, 1)) AS geom INTO matching_geodk_osm._segments_geodk
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

-- CREATE OSM SEGMENTS
WITH data(id, geom) AS (
    SELECT
        id,
        geom
    FROM
        matching_geodk_osm._extract_osm
)
SELECT
    ROW_NUMBER () OVER () AS id,
    id AS id_osm,
    i,
    ST_LineSubstring(geom, startfrac, LEAST(endfrac, 1)) AS geom INTO matching_geodk_osm._segments_osm
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

-- MAKE SURE THAT OSM SEGMENTS ARE NOT TOO SHORT
DROP TABLE IF EXISTS matching_geodk_osm.merged_osm_segments CASCADE;

DROP TABLE IF EXISTS matching_geodk_osm.too_short_osm_segs CASCADE;

CREATE TABLE matching_geodk_osm.merged_osm_segments (
    id_osm decimal,
    long_seg_id integer,
    short_seg_id integer,
    geom geometry
);

CREATE TABLE matching_geodk_osm.too_short_osm_segs AS
SELECT
    *,
    ROW_NUMBER () OVER ()
FROM
    matching_geodk_osm._segments_osm
WHERE
    ST_Length(geom) < 3;

CREATE INDEX idx_osm_short_segs_geometry ON matching_geodk_osm.too_short_osm_segs USING gist(geom);

DO $ $ declare counter integer := 0;

BEGIN while counter < (
    SELECT
        COUNT(*)
    FROM
        matching_geodk_osm.too_short_osm_segs
) loop WITH this_seg AS (
    SELECT
        *
    FROM
        matching_geodk_osm.too_short_osm_segs
    WHERE
        row_number = (counter + 1)
),
neighbor_seg AS (
    SELECT
        *
    FROM
        matching_geodk_osm._segments_osm
    WHERE
        id_osm = (
            SELECT
                id_osm
            FROM
                matching_geodk_osm.too_short_osm_segs
            WHERE
                row_number = (counter + 1)
        )
        AND i = (
            (
                SELECT
                    i
                FROM
                    matching_geodk_osm.too_short_osm_segs
                WHERE
                    row_number = (counter + 1)
            ) - 1
        )
)
INSERT INTO
    matching_geodk_osm.merged_osm_segments
SELECT
    this_seg.id_osm,
    neighbor_seg.i long_seg_id,
    this_seg.i short_seg_id,
    ST_Collect(this_seg.geom, neighbor_seg.geom)
FROM
    this_seg
    JOIN neighbor_seg ON this_seg.id_osm = neighbor_seg.id_osm;

raise notice 'Counter %',
counter;

counter := counter + 1;

END loop;

END $ $;

-- UPDATE GEOMETRIES IN OSM SEGMENTS
UPDATE
    osm_segs
SET
    geom = merged.geom,
FROM
    matching_geodk_osm._segments_osm osm_segs
    JOIN matching_geodk_osm.merged_osm_segments merged ON osm_segs.id_osm = merged.id_osm
    AND osm_segs.i = merged.i;

-- DELETE TOO SHORT OSM SEGMENTS
DELETE FROM
    matching_geodk_osm._segments_osm osm_segs USING matching_geodk_osm.too_short_osm_segs too_short
WHERE
    osm_segs.id_osm = too_short.id_osm
    AND osm_segs.i = too_short.i;

-- MAKE SURE THAT GEODK SEGMENTS ARE NOT TOO SHORT
DROP TABLE IF EXISTS matching_geodk_osm.merged_geodk_segments CASCADE;

DROP TABLE IF EXISTS matching_geodk_osm.too_short_geodk_segs CASCADE;

CREATE TABLE matching_geodk_osm.merged_geodk_segments (
    id_geodk decimal,
    long_seg_id integer,
    short_seg_id integer,
    geom geometry
);

CREATE TABLE matching_geodk_osm.too_short_geodk_segs AS
SELECT
    *,
    ROW_NUMBER () OVER ()
FROM
    matching_geodk_osm._segments_geodk
WHERE
    ST_Length(geom) < 3;

CREATE INDEX idx_geodk_short_segs_geometry ON matching_geodk_osm.too_short_geodk_segs USING gist(geom);

DO $ $ declare counter integer := 0;

BEGIN while counter < (
    SELECT
        COUNT(*)
    FROM
        matching_geodk_osm.too_short_geodk_segs
) loop WITH this_seg AS (
    SELECT
        *
    FROM
        matching_geodk_osm.too_short_geodk_segs
    WHERE
        row_number = (counter + 1)
),
neighbor_seg AS (
    SELECT
        *
    FROM
        matching_geodk_osm._segments_geodk
    WHERE
        id_geodk = (
            SELECT
                id_geodk
            FROM
                matching_geodk_osm.too_short_geodk_segs
            WHERE
                row_number = (counter + 1)
        )
        AND i = (
            (
                SELECT
                    i
                FROM
                    matching_geodk_osm.too_short_geodk_segs
                WHERE
                    row_number = (counter + 1)
            ) - 1
        )
)
INSERT INTO
    matching_geodk_osm.merged_geodk_segments
SELECT
    this_seg.id_geodk,
    neighbor_seg.i long_seg_id,
    this_seg.i short_seg_id,
    ST_Collect(this_seg.geom, neighbor_seg.geom)
FROM
    this_seg
    JOIN neighbor_seg ON this_seg.id_geodk = neighbor_seg.id_geodk;

raise notice 'Counter %',
counter;

counter := counter + 1;

END loop;

END $ $;

-- UPDATE GEOMETRIES IN GEODK SEGMENTS
UPDATE
    geodk_segs
SET
    geom = merged.geom,
FROM
    matching_geodk_osm._segments_geodk geodk_segs
    JOIN matching_geodk_osm.merged_geodk_segments merged ON geodk_segs.id_geodk = merged.id_geodk
    AND geodk_segs.i = merged.i;

-- DELETE TOO SHORT GEODK SEGMENTS
DELETE FROM
    matching_geodk_osm._segments_geodk geodk_segs USING matching_geodk_osm.too_short_geodk_segs too_short
WHERE
    geodk_segs.id_geodk = too_short.id_geodk
    AND geodk_segs.i = too_short.i;

-- SPATIAL INDEX ON GEODK SEGMENTS
CREATE INDEX idx_segments_geodk_seg_geometry ON matching_geodk_osm._segments_geodk USING gist(geom);

-- SPATIAL INDEX ON OSM SEGMENTS
CREATE INDEX idx_segments_osm_geometry ON matching_geodk_osm._segments_osm USING gist(geom);

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
    osm_seg_geom INTO matching_geodk_osm._candidates
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
            matching_geodk_osm._segments_geodk AS segments_geodk
            JOIN matching_geodk_osm._segments_osm AS segments_osm ON ST_Intersects(
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
    _candidates.osm_seg_geom AS geom INTO matching_geodk_osm._matches_osm
FROM
    matching_geodk_osm._candidates AS _candidates
    JOIN (
        SELECT
            osm_seg_id,
            min(hausdorffdist) AS mindist
        FROM
            matching_geodk_osm._candidates
        WHERE
            angle_red < 30
            AND hausdorffdist < 17
        GROUP BY
            osm_seg_id
    ) AS a ON a.osm_seg_id = _candidates.osm_seg_id
    AND mindist = _candidates.hausdorffdist;

CREATE INDEX idx_matches_osm_geometry ON matching_geodk_osm._matches_osm USING gist(geom);

-- Find potential matches - i.e. within thresholds - Using GeoDK gemetries
SELECT
    _candidates.id_geodk,
    _candidates.id_osm,
    _candidates.geodk_seg_id,
    _candidates.osm_seg_id,
    _candidates.angle,
    _candidates.angle_red,
    _candidates.hausdorffdist,
    _candidates.geodk_seg_geom AS geom INTO matching_geodk_osm._matches_geodk
FROM
    matching_geodk_osm._candidates AS _candidates
    JOIN (
        SELECT
            geodk_seg_id,
            min(hausdorffdist) AS mindist
        FROM
            matching_geodk_osm._candidates
        WHERE
            angle_red < 30
            AND hausdorffdist < 17
        GROUP BY
            geodk_seg_id
    ) AS a ON a.geodk_seg_id = _candidates.geodk_seg_id
    AND mindist = _candidates.hausdorffdist;

CREATE INDEX idx_matches_geodk_geometry ON matching_geodk_osm._matches_geodk USING gist(geom);

-- Find unmatched GeoDK segments and match to non-OSM bicycle infra
-- evaluate outcome