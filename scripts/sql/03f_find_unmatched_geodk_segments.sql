-- *** STEP 6: FIND UNMATCHED GEODK SEGMENTS ***
CREATE TABLE matching_geodk_osm_no_bike._segments_geodk AS
SELECT
    *
FROM
    matching_geodk_osm._segments_geodk_all geodk_segs
WHERE
    NOT EXISTS (
        SELECT
            *
        FROM
            matching_geodk_osm_all_bike._matches_geodk geodk_matches
        WHERE
            geodk_segs.id :: VARCHAR = geodk_matches.geodk_seg_id :: VARCHAR
    )
    AND NOT EXISTS (
        SELECT
            *
        FROM
            matching_geodk_osm_no_cycleways._matches_geodk geodk_matches
        WHERE
            geodk_segs.id :: VARCHAR = geodk_matches.geodk_seg_id :: VARCHAR
    );