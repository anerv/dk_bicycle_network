-- *** STEP 4: FIND CANDIDATES***
--
-- **** FIRST FIND CANDICATES BETWEEN OSM ALL BIKE AND GEODK TRACK ****
SELECT
    id_geodk,
    id_osm,
    geodk_seg_id,
    osm_seg_id,
    geodk_unique_seg_id,
    osm_unique_seg_id,
    angle,
    CASE
        WHEN angle > 270 THEN 360 - angle
        WHEN angle > 180 THEN angle -180
        WHEN angle > 90 THEN 180 - angle
        ELSE angle
    END AS angle_red,
    hausdorffdist,
    osm_seg_geom,
    geodk_seg_geom INTO matching_geodk_osm_all_bike._candidates
FROM
    (
        SELECT
            segments_geodk.id_geodk AS id_geodk,
            segments_osm.id_osm AS id_osm,
            segments_geodk.id AS geodk_seg_id,
            segments_osm.id AS osm_seg_id,
            segments_geodk.unique_seg_id AS geodk_unique_seg_id,
            segments_osm.unique_seg_id AS osm_unique_seg_id,
            degrees(
                ST_Angle(
                    st_asText(segments_geodk.geom),
                    st_asText(segments_osm.geom)
                )
            ) AS angle,
            ST_HausdorffDistance(segments_geodk.geom, segments_osm.geom) AS hausdorffdist,
            segments_osm.geom AS osm_seg_geom,
            segments_geodk.geom AS geodk_seg_geom
        FROM
            matching_geodk_osm_all_bike._segments_geodk AS segments_geodk
            JOIN matching_geodk_osm_all_bike._segments_osm AS segments_osm ON ST_Intersects(
                segments_geodk.geom,
                ST_Buffer(segments_osm.geom, 18)
            )
    ) AS A;

-- **** SECOND FIND CANDICATES BETWEEN OSM NO CYCLEWAYS AND GEODK LANE ****
SELECT
    id_geodk,
    id_osm,
    geodk_seg_id,
    osm_seg_id,
    geodk_unique_seg_id,
    osm_unique_seg_id,
    angle,
    CASE
        WHEN angle > 270 THEN 360 - angle
        WHEN angle > 180 THEN angle -180
        WHEN angle > 90 THEN 180 - angle
        ELSE angle
    END AS angle_red,
    hausdorffdist,
    osm_seg_geom,
    geodk_seg_geom INTO matching_geodk_osm_no_cycleways._candidates
FROM
    (
        SELECT
            segments_geodk.id_geodk AS id_geodk,
            segments_osm.id_osm AS id_osm,
            segments_geodk.id AS geodk_seg_id,
            segments_osm.id AS osm_seg_id,
            segments_geodk.unique_seg_id AS geodk_unique_seg_id,
            segments_osm.unique_seg_id AS osm_unique_seg_id,
            degrees(
                ST_Angle(
                    st_asText(segments_geodk.geom),
                    st_asText(segments_osm.geom)
                )
            ) AS angle,
            ST_HausdorffDistance(segments_geodk.geom, segments_osm.geom) AS hausdorffdist,
            segments_osm.geom AS osm_seg_geom,
            segments_geodk.geom AS geodk_seg_geom
        FROM
            matching_geodk_osm_no_cycleways._segments_geodk AS segments_geodk
            JOIN matching_geodk_osm_no_cycleways._segments_osm AS segments_osm ON ST_Intersects(
                segments_geodk.geom,
                ST_Buffer(segments_osm.geom, 18)
            )
    ) AS A;