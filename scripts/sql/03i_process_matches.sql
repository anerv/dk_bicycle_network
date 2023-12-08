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

CREATE INDEX idx_matched_id ON matching_geodk_osm._matches_geodk_all(id_geodk DESC);

CREATE INDEX idx_extract_id ON matching_geodk_osm._extract_geodk(id DESC);

-- GET INFO ON ROAD SURFACE AND CATEGORY
ALTER TABLE
    matching_geodk_osm._matches_geodk_all
ADD
    COLUMN surface VARCHAR DEFAULT NULL,
ADD
    COLUMN road_category VARCHAR DEFAULT NULL;

UPDATE
    matching_geodk_osm._matches_geodk_all
SET
    road_category = 'Cykelbane langs vej',
    surface = 'Befæstet'
WHERE
    id_geodk = (
        SELECT
            DISTINCT id
        FROM
            matching_geodk_osm._extract_geodk
        WHERE
            vejkategori = 'Cykelbane langs vej'
            AND overflade = 'Befæstet'
    );

UPDATE
    matching_geodk_osm._matches_geodk_all
SET
    road_category = 'Cykelsti langs vej',
    surface = 'Befæstet'
WHERE
    id_geodk = (
        SELECT
            DISTINCT id
        FROM
            matching_geodk_osm._extract_geodk
        WHERE
            vejkategori = 'Cykelsti langs vej'
            AND overflade = 'Befæstet'
    );

UPDATE
    matching_geodk_osm._matches_geodk_all
SET
    road_category = 'Cykelsti langs vej',
    surface = 'Ukendt'
WHERE
    id_geodk = (
        SELECT
            DISTINCT id
        FROM
            matching_geodk_osm._extract_geodk
        WHERE
            vejkategori = 'Cykelsti langs vej'
            AND overflade = 'Ukendt'
    );

UPDATE
    matching_geodk_osm._matches_geodk_all
SET
    road_category = 'Cykelbane langs vej',
    surface = 'Ukendt'
WHERE
    id_geodk = (
        SELECT
            DISTINCT id
        FROM
            matching_geodk_osm._extract_geodk
        WHERE
            vejkategori = 'Cykelbane langs vej'
            AND overflade = 'Ukendt'
    );

UPDATE
    matching_geodk_osm._matches_geodk_all
SET
    road_category = 'Cykelsti langs vej',
    surface = 'Ubefæstet'
WHERE
    id_geodk = (
        SELECT
            DISTINCT id
        FROM
            matching_geodk_osm._extract_geodk
        WHERE
            vejkategori = 'Cykelsti langs vej'
            AND overflade = 'Ubefæstet'
    );

UPDATE
    matching_geodk_osm._matches_geodk_all
SET
    road_category = 'Cykelbane langs vej',
    surface = 'Ubefæstet'
WHERE
    id_geodk = (
        SELECT
            DISTINCT id
        FROM
            matching_geodk_osm._extract_geodk
        WHERE
            vejkategori = 'Cykelbane langs vej'
            AND overflade = 'Ubefæstet'
    );

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

UPDATE
    matching_geodk_osm._segments_osm_all o
SET
    surface = g.surface,
    road_category = g.road_category
FROM
    matching_geodk_osm._matches_geodk_all g
WHERE
    o.id = g.osm_seg_id;

-- GROUP SEGMENTS BY ORG EDGE ID
CREATE TABLE matching_geodk_osm._grouped_osm AS
SELECT
    DISTINCT id_osm,
    ARRAY_AGG(
        id
        ORDER BY
            ID
    ) AS ids,
    ARRAY_AGG(DISTINCT matched) AS matched,
    ARRAY_AGG(DISTINCT road_category) AS road,
    ARRAY_AGG(DISTINCT surface) AS surface,
    ARRAY_AGG(
        matched
        ORDER BY
            ID
    ) AS matched_count
FROM
    matching_geodk_osm._segments_osm_all
GROUP BY
    id_osm;

ALTER TABLE
    matching_geodk_osm._grouped_osm
ADD
    COLUMN count_matched INT DEFAULT 0,
ADD
    COLUMN count_unmatched INT DEFAULT 0,
ADD
    COLUMN matched_pct DECIMAL DEFAULT 0,
ADD
    COLUMN matched_final BOOLEAN DEFAULT NULL;

-- COUNT MATCHED
WITH count AS (
    SELECT
        COUNT(*) c,
        id_osm
    FROM
        matching_geodk_osm._segments_osm_all
    WHERE
        matched = TRUE
    GROUP BY
        id_osm
)
UPDATE
    matching_geodk_osm._grouped_osm o
SET
    count_matched = c
FROM
    count
WHERE
    o.id_osm = count .id_osm;

-- COUNT UNMATCHED
WITH count AS (
    SELECT
        COUNT(*) c,
        id_osm
    FROM
        matching_geodk_osm._segments_osm_all
    WHERE
        matched = FALSE
    GROUP BY
        id_osm
)
UPDATE
    matching_geodk_osm._grouped_osm o
SET
    count_unmatched = c
FROM
    count
WHERE
    o.id_osm = count .id_osm;

-- DELETE ALL THAT ARE COMPLETELY UNMATCHED
DELETE FROM
    matching_geodk_osm._grouped_osm
WHERE
    matched = '{f}';

UPDATE
    matching_geodk_osm._grouped_osm
SET
    matched_pct = count_matched :: DECIMAL / (
        count_unmatched :: DECIMAL + count_matched :: DECIMAL
    ) * 100;

UPDATE
    matching_geodk_osm._grouped_osm
SET
    matched_final = CASE
        WHEN matched_pct < 30 THEN FALSE
        WHEN matched_pct > 70 THEN TRUE -- WHEN matched_pct > 49.9
        -- AND count_matched + count_unmatched < 3 THEN TRUE
        -- WHEN matched_pct > 66
        -- AND count_matched + count_unmatched < 4 THEN TRUE
        WHEN matched_pct > 49.9
        AND count_matched + count_unmatched < 7 THEN TRUE
    END;

-- SET AS MATCHED FALSE FOR REMAINING WITH ONLY ONE MATCHED SEGMENT
UPDATE
    matching_geodk_osm._grouped_osm
SET
    matched_final = FALSE
WHERE
    count_matched = 1;

CREATE TABLE matching_geodk_osm._undecided_groups AS (
    SELECT
        *
    FROM
        matching_geodk_osm._grouped_osm
    WHERE
        matched_final IS NULL
        AND id_osm IN (
            SELECT
                id_osm
            FROM
                matching_geodk_osm._segments_osm_all
            WHERE
                bicycle_infrastructure IS FALSE
        )
);

CREATE TABLE matching_geodk_osm._undecided_segments AS
SELECT
    *
FROM
    matching_geodk_osm._segments_osm_all
WHERE
    id_osm IN (
        SELECT
            id_osm
        FROM
            matching_geodk_osm._grouped_osm
        WHERE
            matched_final IS NULL
    )
    AND bicycle_infrastructure IS FALSE;

--
--- NOW, FOR ALL THAT REMAINS - I.e. with matched_final being null - split
---
-- -- TODO: DEAL WITH MATCHED WITH DIFFERENT CATEGORY - ONLY THOSE THAT DO NOT ALREADY HAVE BIKE INFRA
-- -- TODO: close small gaps - reuse method from above
-- TopoGeo_AddPoint,
-- ST_NewEdgesSplit
-- and ST_ModEdgeSplit pgr_createTopology pgr_analyzeGraph --******
-- COMPUTE RATIO BETWEEN MATCHED AND UNMATCHED
-- CREATE TABLE matching_geodk_osm._undecided AS
-- SELECT
--     *
-- FROM
--     matching_geodk_osm._segments_osm_all
-- WHERE
--     id_osm IN (
--         SELECT
--             id_osm
--         FROM
--             matching_geodk_osm._grouped_osm
--     );
-- 
-- FOR _grouped_osm: COUNT matched and unmatched in each group
-- CREATE VIEW matching_geodk_osm._matched_osm_segments AS
-- SELECT
--     *
-- FROM
--     matching_geodk_osm._segments_osm_all
-- WHERE
--     matched = TRUE;
-- CREATE VIEW matching_geodk_osm._unmatched_osm_segments AS
-- SELECT
--     *
-- FROM
--     matching_geodk_osm._segments_osm_all
-- WHERE
--     matched = FALSE;
-- CREATE VIEW/LIST WITH START AND END NODES OF MATCHED SEGMENTS
-- MARK UNMATCHED SEGS AS POTENTIAL MATCHED IF BOTH THEIR START AND END NODES ARE IN MATCHED NODES
-- CREATE TABLE matched_nodes AS
-- SELECT
--     u
-- FROM
--     osm_edges_simplified
-- WHERE
--     geodk_bike IS NOT NULL
-- UNION
-- SELECT
--     v
-- FROM
--     osm_edges_simplified
-- WHERE
--     geodk_bike IS NOT NULL;
-- -- FIND UNMATCHED SEGMENTS BETWEEN MATCHED SEGMENTS 
-- -- TODO: GROUP OSM EDGES AS MATCHED
-- CREATE TABLE gaps AS
-- SELECT
--     *
-- FROM
--     potential_gaps
-- WHERE
--     u IN (
--         SELECT
--             u
--         FROM
--             matched_nodes
--     )
--     AND v IN (
--         SELECT
--             u
--         FROM
--             matched_nodes
--     )
--     AND name in (
--         SELECT
--             NAME
--         FROM
--             matched_names
--     )
--     AND ST_Length(geometry) < 20;
---- *****
-- -- NOT MATCHED AT ALL
-- DELETE FROM
--     matching_geodk_osm._grouped_osm
-- WHERE
--     matched = '{f}';
-- -- COMPLETELY MATCHED
-- CREATE TABLE matching_geodk_osm._matched_osm_edges AS
-- SELECT
--     *
-- FROM
--     matching_geodk_osm._grouped_osm
-- WHERE
--     matched = '{t}';
-- DELETE FROM
--     matching_geodk_osm._grouped_osm
-- WHERE
--     matched = '{t}';
-- -- ALREADY MARKED AS BICYCLE INFRASTRUCTURE
-- DELETE FROM
--     matching_geodk_osm._grouped_osm
-- WHERE
--     id_osm IN (
--         SELECT
--             id
--         FROM
--             osm_road_edges
--         WHERE
--             bicycle_infrastructure = TRUE
--     );
-- -- MARK SEGMENTS AS MATCHED IF THEY ARE BETWEEN MATCHED SEGMENTS
-- ALTER TABLE
--     matching_geodk_osm._segments_osm_all
-- ADD
--     COLUMN new_id SERIAL PRIMARY KEY,
-- ADD
--     COLUMN source INT,
-- ADD
--     COLUMN target INT,
-- ADD
--     COLUMN the_geom TEXT;
-- ALTER TABLE
--     matching_geodk_osm._segments_osm_all
-- ALTER COLUMN
--     geom TYPE geometry(LineString, 25832) USING ST_Force2D(geom);
-- UPDATE
--     matching_geodk_osm._segments_osm_all
-- SET
--     the_geom = ST_AsText(geom);
-- -- POSSIBLY SPEED UP BY ONLY INCLUDING MATCHED OR THOSE CLOSE TO A MATCHED SEGMENTS
-- SELECT
--     pgr_createTopology(
--         'matching_geodk_osm._segments_osm_all',
--         0.001,
--         'the_geom',
--         'new_id',
--         'source',
--         'target'
--     );
-- WITH matched_nodes AS (
--     SELECT
--         source
--     FROM
--         matching_geodk_osm._segments_osm_all
--     WHERE
--         matched = TRUE
--     UNION
--     SELECT
--         target
--     FROM
--         matching_geodk_osm._segments_osm_all
-- ) CREATE VIEW unmatched_gaps AS
-- SELECT
--     *
-- FROM
--     matching_geodk_osm._segments_osm_all
-- WHERE
--     matched = FALSE
--     AND source IN matched_nodes
--     AND target IN matched_nodes;
-- ---
-- --- CHECK IF CORRECT HERE!!
-- ---
-- UPDATE
--     matching_geodk_osm._segments_osm_all
-- SET
--     matched = TRUE
-- WHERE
--     id IN (
--         SELECT
--             id
--         FROM
--             unmatched_gaps
--     );