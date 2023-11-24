-- *** STEP 2: CREATE SEGMENTS ***
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

-- CREATE UNIQUE SEGMENT ID OSM
ALTER TABLE
    matching_geodk_osm._segments_osm
ADD
    COLUMN unique_seg_id VARCHAR;

ALTER TABLE
    matching_geodk_osm._segments_osm
ADD
    COLUMN neighbor_seg_id VARCHAR;

UPDATE
    matching_geodk_osm._segments_osm
SET
    unique_seg_id = CAST (id AS text) || '_' || CAST (i AS text);

UPDATE
    matching_geodk_osm._segments_osm
SET
    neighbor_seg_id = CAST ((id -1) AS text) || '_' || CAST ((i -1) AS text);

DO $$
DECLARE
    count_unique_seg_id INT;

BEGIN
    SELECT
        COUNT(DISTINCT unique_seg_id) INTO count_unique_seg_id
    FROM
        matching_geodk_osm._segments_osm;

ASSERT count_unique_seg_id = (
    SELECT
        COUNT(*)
    FROM
        matching_geodk_osm._segments_osm
),
'OSM seg IDS not unique';

END $$;

-- CREATE UNIQUE SEGMENT ID GEODK
ALTER TABLE
    matching_geodk_osm._segments_geodk
ADD
    COLUMN unique_seg_id VARCHAR;

ALTER TABLE
    matching_geodk_osm._segments_geodk
ADD
    COLUMN neighbor_seg_id VARCHAR;

UPDATE
    matching_geodk_osm._segments_geodk
SET
    unique_seg_id = CAST (id AS text) || '_' || CAST (i AS text);

UPDATE
    matching_geodk_osm._segments_geodk
SET
    neighbor_seg_id = CAST (id -1 AS text) || '_' || CAST ((i -1) AS text);

DO $$
DECLARE
    count_unique_seg_id INT;

BEGIN
    SELECT
        COUNT(DISTINCT unique_seg_id) INTO count_unique_seg_id
    FROM
        matching_geodk_osm._segments_geodk;

ASSERT count_unique_seg_id = (
    SELECT
        COUNT(*)
    FROM
        matching_geodk_osm._segments_geodk
),
'GeoDK seg IDS not unique';

END $$;

-- MAKE SURE THAT OSM SEGMENTS ARE NOT TOO SHORT
DROP TABLE IF EXISTS matching_geodk_osm.merged_osm_segments CASCADE;

DROP TABLE IF EXISTS matching_geodk_osm.too_short_osm_segs CASCADE;

CREATE TABLE matching_geodk_osm.merged_osm_segments (
    id_osm decimal,
    long_seg_id VARCHAR,
    short_seg_id VARCHAR,
    long_i VARCHAR,
    short_i VARCHAR,
    geom geometry
);

CREATE TABLE matching_geodk_osm.too_short_osm_segs AS
SELECT
    *
FROM
    matching_geodk_osm._segments_osm
WHERE
    ST_Length(geom) < 3;

CREATE INDEX idx_osm_short_segs_geometry ON matching_geodk_osm.too_short_osm_segs USING gist(geom);

WITH joined_data AS (
    SELECT
        short_segs.id_osm AS id_osm,
        neighbor_segs.unique_seg_id AS long_seg_id,
        short_segs.unique_seg_id AS short_seg_id,
        neighbor_segs.i AS long_i,
        short_segs.i AS short_i,
        ST_Collect(short_segs.geom, neighbor_segs.geom) AS geom
    FROM
        matching_geodk_osm.too_short_osm_segs short_segs
        JOIN matching_geodk_osm._segments_osm neighbor_segs ON short_segs.neighbor_seg_id = neighbor_segs.unique_seg_id
)
INSERT INTO
    matching_geodk_osm.merged_osm_segments
SELECT
    *
FROM
    joined_data;

-- MERGE MULTILINESTRINGS
UPDATE
    matching_geodk_osm.merged_osm_segments
SET
    geom = ST_LineMerge(geom);

-- UPDATE GEOMETRIES IN OSM SEGMENTS
WITH joined_data AS (
    SELECT
        merged.geom AS new_geom,
        osm_segs.unique_seg_id AS seg_id
    FROM
        matching_geodk_osm._segments_osm osm_segs
        JOIN matching_geodk_osm.merged_osm_segments merged ON osm_segs.unique_seg_id = merged.long_seg_id
)
UPDATE
    matching_geodk_osm._segments_osm
SET
    geom = new_geom
FROM
    joined_data
WHERE
    unique_seg_id = joined_data.seg_id;

-- DELETE TOO SHORT OSM SEGMENTS
DELETE FROM
    matching_geodk_osm._segments_osm osm_segs USING matching_geodk_osm.too_short_osm_segs too_short
WHERE
    osm_segs.unique_seg_id = too_short.unique_seg_id;

-- MAKE SURE GEODK SEGMENTS ARE NOT TOO SHORT
DROP TABLE IF EXISTS matching_geodk_osm.merged_geodk_segments CASCADE;

DROP TABLE IF EXISTS matching_geodk_osm.too_short_geodk_segs CASCADE;

CREATE TABLE matching_geodk_osm.merged_geodk_segments (
    id_geodk decimal,
    long_seg_id VARCHAR,
    short_seg_id VARCHAR,
    long_i VARCHAR,
    short_i VARCHAR,
    geom geometry
);

CREATE TABLE matching_geodk_osm.too_short_geodk_segs AS
SELECT
    *
FROM
    matching_geodk_osm._segments_geodk
WHERE
    ST_Length(geom) < 3;

CREATE INDEX idx_geodk_short_segs_geometry ON matching_geodk_osm.too_short_geodk_segs USING gist(geom);

WITH joined_data AS (
    SELECT
        short_segs.id_geodk :: DECIMAL AS id_geodk,
        neighbor_segs.unique_seg_id AS long_seg_id,
        short_segs.unique_seg_id AS short_seg_id,
        neighbor_segs.i AS long_i,
        short_segs.i AS short_i,
        ST_Collect(short_segs.geom, neighbor_segs.geom) AS geom
    FROM
        matching_geodk_osm.too_short_geodk_segs short_segs
        JOIN matching_geodk_osm._segments_geodk neighbor_segs ON short_segs.neighbor_seg_id = neighbor_segs.unique_seg_id
)
INSERT INTO
    matching_geodk_osm.merged_geodk_segments
SELECT
    *
FROM
    joined_data;

-- MERGE MULTILINESTRINGS
UPDATE
    matching_geodk_osm.merged_geodk_segments
SET
    geom = ST_LineMerge(geom);

-- UPDATE GEOMETRIES IN geodk SEGMENTS
WITH joined_data AS (
    SELECT
        merged.geom AS new_geom,
        geodk_segs.unique_seg_id AS seg_id
    FROM
        matching_geodk_osm._segments_geodk geodk_segs
        JOIN matching_geodk_osm.merged_geodk_segments merged ON geodk_segs.unique_seg_id = merged.long_seg_id
)
UPDATE
    matching_geodk_osm._segments_geodk
SET
    geom = new_geom
FROM
    joined_data
WHERE
    unique_seg_id = joined_data.seg_id;

-- DELETE TOO SHORT geodk SEGMENTS
DELETE FROM
    matching_geodk_osm._segments_geodk geodk_segs USING matching_geodk_osm.too_short_geodk_segs too_short
WHERE
    geodk_segs.unique_seg_id = too_short.unique_seg_id;

-- SPATIAL INDEX ON GEODK SEGMENTS
CREATE INDEX idx_segments_geodk_seg_geometry ON matching_geodk_osm._segments_geodk USING gist(geom);

-- SPATIAL INDEX ON OSM SEGMENTS
CREATE INDEX idx_segments_osm_geometry ON matching_geodk_osm._segments_osm USING gist(geom);