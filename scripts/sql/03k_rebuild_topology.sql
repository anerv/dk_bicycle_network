-- rebuild topology
SELECT
    pgr_createTopology(
        'osm_road_edges',
        0.001,
        'geometry',
        'id',
        'source',
        'target',
        clean := true
    );