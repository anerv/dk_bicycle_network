-- *** STEP 9: PROCESS MATCHES ***
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
    COUNT(DISTINCT geodk_seg_id) INTO count_unique_id
FROM
    matching_geodk_osm._matches_geodk_all;

ASSERT count_unique_id = (
    SELECT
        COUNT(*)
    FROM
        matching_geodk_osm._matches_geodk_all
),
'GeoDK matches segment IDS not unique';

END $ $;

BEGIN
SELECT
    COUNT(DISTINCT id) INTO count_unique_id
FROM
    matching_geodk_osm._segments_osm_all;

ASSERT count_unique_id = (
    SELECT
        COUNT(*)
    FROM
        matching_geodk_osm._segments_osm_all
),
'OSM IDS not unique';

END $ $;