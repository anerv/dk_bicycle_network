DROP INDEX IF EXISTS osm_road_edges_vertices_pgr_the_geom_idx;

SELECT
    pgr_createverticestable('osm_road_edges', 'geometry', 'source', 'target');

COMMIT;