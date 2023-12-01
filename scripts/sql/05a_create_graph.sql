SELECT
    pgr_createverticestable('osm_road_edges', 'geometry', 'source', 'target');

pgr_dijkstra(osm_road_edges, 731996, 427106)