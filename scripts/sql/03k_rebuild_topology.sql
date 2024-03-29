DROP TABLE IF EXISTS nodes;

DROP TABLE IF EXISTS osm_road_edges_vertices_pgr;

-- rebuild topology
SELECT
    pgr_createTopology(
        'osm_road_edges',
        0.001,
        'geometry',
        'id',
        'source',
        'target',
        clean := TRUE
    );