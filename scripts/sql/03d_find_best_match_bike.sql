-- *** STEP 4: FIND BEST MATCHES BETWEEN CYCLING INFRA ***
SELECT
    _candidates.id_geodk,
    _candidates.id_osm,
    _candidates.geodk_seg_id,
    _candidates.osm_seg_id,
    _candidates.angle,
    _candidates.angle_red,
    _candidates.hausdorffdist,
    _candidates.geodk_seg_geom AS geom INTO matching_geodk_osm._matches_geodk
FROM
    matching_geodk_osm._candidates AS _candidates
    JOIN (
        SELECT
            geodk_seg_id,
            min(hausdorffdist) AS mindist
        FROM
            matching_geodk_osm._candidates
        WHERE
            angle_red < 30
            AND hausdorffdist < 17
        GROUP BY
            geodk_seg_id
    ) AS a ON a.geodk_seg_id = _candidates.geodk_seg_id
    AND mindist = _candidates.hausdorffdist;

CREATE INDEX idx_matches_geodk_geometry ON matching_geodk_osm._matches_geodk USING gist(geom);