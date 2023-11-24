-- *** STEP 5: FIND UNMATCHED GEODK SEGMENTS ***
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
            geodk_segs.id :: VARCHAR = geodk_matches.geodk_seg_id :: VARCHAR
    );