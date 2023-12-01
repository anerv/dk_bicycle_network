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

CREATE INDEX idx_matched_id ON matching_geodk_osm._matches_geodk_all(id_geodk, DESC);

CREATE INDEX idx_extract_id ON matching_geodk_osm._extract_geodk(id, DESC);

-- GET INFO ON ROAD SURFACE AND CATEGORY
ALTER TABLE
    matching_geodk_osm._matches_geodk_all
ADD
    COLUMN surface VARCHAR DEFAULT NULL,
ADD
    COLUMN road_category VARCHAR DEFAULT NULL;

UPDATE
    matching_geodk_osm._matches_geodk_all m
SET
    surface = overflade,
    road_category = vejkategori
FROM
    matching_geodk_osm._extract_geodk g
WHERE
    m.id_geodk = g.id;

-- UPDATE
--     matching_geodk_osm._matches_geodk_all m
-- SET
--     road_category = vejkategori
-- FROM
--     matching_geodk_osm._extract_geodk g
-- WHERE
--     m.id_geodk = g.id;
-- TRANSFER INFO TO OSM SEGMENTS
ALTER TABLE
    matching_geodk_osm._segments_osm_all
ADD
    COLUMN matched BOOL DEFAULT FALSE,
ADD
    COLUMN surface VARCHAR DEFAULT NULL,
ADD
    COLUMN road_category VARCHAR DEFAULT NULL;

UPDATE
    matching_geodk_osm._segments_osm_all
SET
    matched = TRUE
WHERE
    id IN (
        SELECT
            osm_seg_id
        FROM
            matching_geodk_osm._matches_geodk_all
        ORDER BY
            osm_seg_id
    );

-- IF WORKED - use similiar method with where for other steps
-- UPDATE
--     matching_geodk_osm._segments_osm_all o
-- SET
--     matched = TRUE
-- FROM
--     matching_geodk_osm._matches_geodk_all g
-- WHERE
--     o.id_osm = g.osm_seg_id;
UPDATE
    matching_geodk_osm._segments_osm_all o
SET
    o.surface = g.surface,
    o.road_category = g.road_category
FROM
    matching_geodk_osm._matches_geodk_all g
WHERE
    o.id_osm = g.osm_seg_id;

-- UPDATE
--     matching_geodk_osm._segments_osm_all o
-- SET
--     o.surface = g.surface
-- FROM
--     matching_geodk_osm._matches_geodk_all g
-- WHERE
--     o.id_osm = g.osm_seg_id;
-- TODO: CHECK THAT MATCHED OSM SEGS ARE CORRECT!!
-- TODO: GROUP OSM EDGES AS MATCHED