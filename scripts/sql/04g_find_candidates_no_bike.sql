-- *** STEP 7: FIND CANDIDATES GEODK OSM NO BIKE ***
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
    osm_seg_geom INTO matching_geodk_osm_no_bike._candidates
FROM
    (
        SELECT
            segments_geodk.id_geodk AS id_geodk,
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
            matching_geodk_osm_no_bike._segments_geodk AS segments_geodk
            JOIN matching_geodk_osm_no_bike._segments_osm AS segments_osm ON ST_Intersects(
                segments_osm.geom,
                ST_Buffer(segments_geodk.geom, 15)
            )
    ) AS a;