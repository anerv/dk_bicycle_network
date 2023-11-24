---- TODO
-- confirm that geodk unmatched are correct
-- drop osm matches tables to make sure that it is not used
-- match
-- INSERT_ IN ALL TABLE NAMES
-- 
---
--- COMBINE GEODK MATCHES FROM BIKE AND NO BIKE
CREATE TABLE matching_geodk_osm._matches_geodk_all AS (
    SELECT
        *
    FROM
        matching_geodk_osm._matches_geodk
    UNION
    SELECT
        *
    FROM
        matching_geodk_osm_no_bike._matches_geodk
);

--- COMBINE OSM SEGMENTS FROM BIKE AND NO BIKE
CREATE TABLE matching_geodk_osm._segments_osm_all AS (
    SELECT
        *
    FROM
        matching_geodk_osm._segments_osm
    UNION
    SELECT
        *
    FROM
        matching_geodk_osm_no_bike._segments_osm
);

-- CHECK THAT OSM SEG ID IS STILL UNIQUE
BEGIN
SELECT
    COUNT(DISTINCT unique_seg_id) INTO count_unique_seg_id
FROM
    matching_geodk_osm_no_bike._segments_osm_all;

ASSERT count_unique_seg_id = (
    SELECT
        COUNT(*)
    FROM
        matching_geodk_osm_no_bike._segments_osm_all
),
'OSM seg IDS not unique';

END $ $;

BEGIN
SELECT
    COUNT(DISTINCT id) INTO count_unique_id
FROM
    matching_geodk_osm_no_bike._segments_osm_all;

ASSERT count_unique_id = (
    SELECT
        COUNT(*)
    FROM
        matching_geodk_osm_no_bike._segments_osm_all
),
'OSM IDS not unique';

END $ $;

-- MARK OSM SEGMENTS AS MATCHED
ALTER TABLE
    matching_geodk_osm._segments_osm_all
ADD
    COLUMN matched BOOL DEFAULT FALSE,
    COLUMN geodk_category VARCHAR DEFAULT NULL,
    COLUMN geodk_surface VARCHAR DEFAULT NULL;

UPDATE
    matching_geodk_osm._segments_osm_all o
SET
    matched = TRUE
FROM
    matching_geodk_osm._matches_geodk_all g
WHERE
    o.id = g.id_osm;

-- TODO: TRANSFER vejkategori and surface TO OSM SEGMENTS
-- TODO: FIRST GET VEJKATEGORI AND SURFACE TO OSM MATCHES
-- THEN TRANSFER TO SEGMENTS
-- group osm_segs by org_id
-- if more than XXX segs are matched -- mark as matched?
-- find org geodk if of majority of segment matches or just find their values for type and surface
-- store in new column for osm roads
-- make new bicycle infra column
--
-- TODO: CLOSE GAPS