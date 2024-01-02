SELECT
    pgr_createverticestable('osm_road_edges', 'geometry', 'source', 'target');

COMMIT;