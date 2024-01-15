-- TODO: deal with highway=footway bicycle crossings (LTS issue)
-- TODO: deal with highway = 'cycleway' and bicycle class is 2 or 3 (e.g. because of crossing) (LTS issue)
-- FIX highway=footway and category = crossing (LTS issue)
-- FIX highway=pedestrian and category = crossing (LTS issue)
-- GIVE THEM HIGHEST LTS OF THEIR NODES
-- **
-- make sure that all bike that has no lts are crossings?
-- ***
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

-- DO $$
-- DECLARE
--     lts_error INT;
-- BEGIN
--     SELECT
--         COUNT(*) INTO lts_error
--     FROM
--         osm_road_edges
--     WHERE
--         lts IS NOT NULL
--         AND lts <> 999
--         AND car_traffic IS FALSE
--         AND cycling_allowed IS FALSE;
-- ASSERT lts_error = 0,
-- 'Edges with surplus LTS value';
-- END $$;
DROP VIEW IF EXISTS nodes_lts_999;

DROP VIEW IF EXISTS nodes_lts_0;

DROP VIEW IF EXISTS nodes_lts_1;

DROP VIEW IF EXISTS nodes_lts_2;

DROP VIEW IF EXISTS nodes_lts_3;

DROP VIEW IF EXISTS nodes_lts_4;

DROP TABLE IF EXISTS crossings;