-- *** STEP 3: PROCESS SEGMENTS ***
ALTER TABLE
    matching_geodk_osm._segments_osm_all
ADD
    COLUMN bicycle_infrastructure BOOLEAN DEFAULT FALSE;

ALTER TABLE
    matching_geodk_osm._segments_geodk_all
ADD
    COLUMN road_category VARCHAR DEFAULT FALSE;

UPDATE
    matching_geodk_osm._segments_osm_all o
SET
    bicycle_infrastructure = TRUE
WHERE
    id_osm IN (
        SELECT
            id
        FROM
            matching_geodk_osm._extract_osm
        WHERE
            bicycle_infrastructure IS TRUE
    );

UPDATE
    matching_geodk_osm._segments_geodk_all
SET
    road_category = 'Cykelsti langs vej'
WHERE
    id_geodk IN (
        SELECT
            id
        FROM
            matching_geodk_osm._extract_geodk
        WHERE
            vejkategori = 'Cykelsti langs vej'
    );

UPDATE
    matching_geodk_osm._segments_geodk_all
SET
    road_category = 'Cykelbane langs vej'
WHERE
    id_geodk IN (
        SELECT
            id
        FROM
            matching_geodk_osm._extract_geodk
        WHERE
            vejkategori = 'Cykelbane langs vej'
    );

-- CREATE OSM SEGMENTS WITH AND WITHOUT BIKE
CREATE TABLE matching_geodk_osm_all_bike._segments_osm AS (
    SELECT
        *
    FROM
        matching_geodk_osm._segments_osm_all
    WHERE
        bicycle_infrastructure IS TRUE
);

CREATE TABLE matching_geodk_osm_no_cycleways._segments_osm AS (
    SELECT
        *
    FROM
        matching_geodk_osm_all_bike._segments_osm
    WHERE
        id_osm IN (
            SELECT
                id
            FROM
                matching_geodk_osm._extract_osm
            WHERE
                highway NOT IN ('cycleway', 'path', 'track')
        )
);

CREATE TABLE matching_geodk_osm_no_bike._segments_osm AS (
    SELECT
        *
    FROM
        matching_geodk_osm._segments_osm_all
    WHERE
        bicycle_infrastructure IS FALSE
);

-- CREATE GEODK SEGMENTS BASED ON VEJKATEGORI
CREATE TABLE matching_geodk_osm_all_bike._segments_geodk AS (
    SELECT
        *
    FROM
        matching_geodk_osm._segments_geodk_all
    WHERE
        road_category = 'Cykelsti langs vej'
);

CREATE TABLE matching_geodk_osm_no_cycleways._segments_geodk AS (
    SELECT
        *
    FROM
        matching_geodk_osm._segments_geodk_all
    WHERE
        road_category = 'Cykelbane langs vej'
);

-- SPATIAL INDEX ON OSM SEGMENTS
CREATE INDEX idx_segments_osm_all_bike_geometry ON matching_geodk_osm_all_bike._segments_osm USING gist(geom);

CREATE INDEX idx_segments_osm_no_cycleways_geometry ON matching_geodk_osm_no_cycleways._segments_osm USING gist(geom);

CREATE INDEX idx_segments_osm_no_bike_geometry ON matching_geodk_osm_no_bike._segments_osm USING gist(geom);

CREATE INDEX idx_segments_geodk_track_geom ON matching_geodk_osm_all_bike._segments_geodk USING gist(geom);

CREATE INDEX idx_segments_geodk_lane_geom ON matching_geodk_osm_no_cycleways._segments_geodk USING gist(geom);