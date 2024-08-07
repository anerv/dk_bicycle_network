CREATE INDEX IF NOT EXISTS osm_road_edges_source_idx ON osm_road_edges (source);

CREATE INDEX IF NOT EXISTS osm_road_edges_target_idx ON osm_road_edges (target);

CREATE TABLE crossings AS (
    SELECT
        *
    FROM
        osm_road_edges
    WHERE
        bicycle_infrastructure_final IS TRUE
        AND lts IS NULL
        AND bicycle_category = 'crossing'
);

UPDATE
    crossings
SET
    lts = CASE
        WHEN source IN (
            SELECT
                node
            FROM
                nodes_lts_4
        )
        OR target IN (
            SELECT
                node
            FROM
                nodes_lts_4
        ) THEN 4
        WHEN source IN (
            SELECT
                node
            FROM
                nodes_lts_3
        )
        OR target IN (
            SELECT
                node
            FROM
                nodes_lts_3
        ) THEN 3
        WHEN source IN (
            SELECT
                node
            FROM
                nodes_lts_2
        )
        OR target IN (
            SELECT
                node
            FROM
                nodes_lts_2
        ) THEN 2
        WHEN source IN (
            SELECT
                node
            FROM
                nodes_lts_1
        )
        OR target IN (
            SELECT
                node
            FROM
                nodes_lts_1
        ) THEN 1
    END;

UPDATE
    osm_road_edges o
SET
    lts = cr.lts
FROM
    crossings cr
WHERE
    o.id = cr.id
    AND o.lts IS NULL;

DO $$
DECLARE
    lts_missing INT;

BEGIN
    SELECT
        COUNT(*) INTO lts_missing
    FROM
        osm_road_edges
    WHERE
        lts IS NULL
        AND bicycle_infrastructure_final IS TRUE;

ASSERT lts_missing = 0,
'Cycling edges missing LTS value';

END $$;

DROP VIEW IF EXISTS nodes_lts_999;

DROP VIEW IF EXISTS nodes_lts_0;

DROP VIEW IF EXISTS nodes_lts_1;

DROP VIEW IF EXISTS nodes_lts_2;

DROP VIEW IF EXISTS nodes_lts_3;

DROP VIEW IF EXISTS nodes_lts_4;

DROP TABLE IF EXISTS crossings;