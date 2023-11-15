--- ##### STEP 1 ######## ----
-- FIND UNMATCHED GEODK SEGMENTS
-- CREATE UNIQUE SEG ID COLUMN IN MATCHES AND SEGMENTS
ALTER TABLE
    matching_geodk_osm._segments_geodk
ADD
    COLUMN unique_seg_id decimal;

UPDATE
    matching_geodk_osm._segments_geodk
SET
    unique_seg_id = matching_geodk_osm._segments_geodk.id_geodk + matching_geodk_osm._segments_geodk.i;

ALTER TABLE
    matching_geodk_osm._matches_geodk
ADD
    COLUMN unique_seg_id decimal;

UPDATE
    matching_geodk_osm._matches_geodk_geodk
SET
    unique_seg_id = matching_geodk_osm._matches_geodk.id_geodk + matching_geodk_osm._matches_geodk.i;

CREATE TABLE matching_geodk_osm.unmatched_geodk_segments AS
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
            geodk_segs.unique_seg_id = geodk_matches.unique_seg_id
    );

--- ##### STEP 2 ######## ----
-- ###### PREPARE GEOMETRIES ###########
--
-- MERGE LINESTRINGS OSM
SELECT
    min(osm_id) AS id,
    (
        st_dump(ST_LineMerge(st_union(ST_Force2D(geometry))))
    ).geom AS geom INTO matching_geodk_osm._extract_osm_no_bike -- UPDATE
FROM
    osm_roads
WHERE
    bicycle_infrastructure IS FALSE -- THIS TIME NON BIKE OSM DATA
GROUP BY
    osm_id,
    bicycle_infrastructure;

--- ##### STEP 3 ######## ----
-- ### CREATE SEGMENTS ##### ---
--
-- CREATE OSM SEGMENTS
WITH data(id, geom) AS (
    SELECT
        id,
        geom
    FROM
        matching_geodk_osm._extract_osm_no_bike
)
SELECT
    ROW_NUMBER () OVER () AS id,
    id AS id_osm,
    i,
    ST_LineSubstring(geom, startfrac, LEAST(endfrac, 1)) AS geom INTO matching_geodk_osm.segments_osm_no_bike
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
DROP TABLE IF EXISTS matching_geodk_osm.merged_osm_segments_no_bike CASCADE;

DROP TABLE IF EXISTS matching_geodk_osm.too_short_osm_segs_no_bike CASCADE;

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
    matching_geodk_osm.segments_osm_no_bike
WHERE
    ST_Length(geom) < 3;

CREATE INDEX idx_osm_short_segs_geometry ON matching_geodk_osm.too_short_osm_segs_no_bike USING gist(geom);

DO $ $ declare counter integer := 0;

BEGIN while counter < (
    SELECT
        COUNT(*)
    FROM
        matching_geodk_osm.too_short_osm_segs_no_bike
) loop WITH this_seg AS (
    SELECT
        *
    FROM
        matching_geodk_osm.too_short_osm_segs_no_bike
    WHERE
        row_number = (counter + 1)
),
neighbor_seg AS (
    SELECT
        *
    FROM
        matching_geodk_osm.segments_osm_no_bike
    WHERE
        id_osm = (
            SELECT
                id_osm
            FROM
                matching_geodk_osm.too_short_osm_segs_no_bike
            WHERE
                row_number = (counter + 1)
        )
        AND i = (
            (
                SELECT
                    i
                FROM
                    matching_geodk_osm.too_short_osm_segs_no_bike
                WHERE
                    row_number = (counter + 1)
            ) - 1
        )
)
INSERT INTO
    matching_geodk_osm.merged_osm_segments_no_bike
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
    matching_geodk_osm.segments_osm_no_bike osm_segs
    JOIN matching_geodk_osm.merged_osm_segments_no_bike merged ON osm_segs.id_osm = merged.id_osm
    AND osm_segs.i = merged.i;

-- DELETE TOO SHORT OSM SEGMENTS
DELETE FROM
    matching_geodk_osm.segments_osm_no_bike osm_segs USING matching_geodk_osm.too_short_osm_segs_no_bike too_short
WHERE
    osm_segs.id_osm = too_short.id_osm
    AND osm_segs.i = too_short.i;

-- TODO: BELOW - UPDATE TABLES!!
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
    osm_seg_geom INTO matching_geodk_osm._candidates_no_bike
FROM
    (
        SELECT
            segments_geodk.id_geodk AS id_geodk,
            -- UPDATE HERE - unmachted geodk segments and osm no bike segments
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
            JOIN matching_geodk_osm.segments_osm_no_bike AS segments_osm ON ST_Intersects(
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
    _candidates.osm_seg_geom AS geom INTO matching_geodk_osm._matches_osm --UPDATE HERE - new table with new matches
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

--UPDATE HERE - new table with new matches
-- Find potential matches - i.e. within thresholds - Using GeoDK gemetries
SELECT
    _candidates.id_geodk,
    _candidates.id_osm,
    _candidates.geodk_seg_id,
    _candidates.osm_seg_id,
    _candidates.angle,
    _candidates.angle_red,
    _candidates.hausdorffdist,
    _candidates.geodk_seg_geom AS geom INTO matching_geodk_osm._matches_geodk --UPDATE HERE - new table with new matches
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

--UPDATE HERE - new table with new matches