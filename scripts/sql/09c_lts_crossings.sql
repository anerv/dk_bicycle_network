-- TODO: deal with highway=footway bicycle crossings (LTS issue)
-- TODO: deal with highway = 'cycleway' and bicycle class is 2 or 3 (e.g. because of crossing) (LTS issue)
-- FIX highway=footway and category = crossing (LTS issue)
-- FIX highway=pedestrian and category = crossing (LTS issue)
-- GIVE THEM HIGHEST LTS OF THEIR NODES
UPDATE
    osm_road_edges
SET
    lts = 2
WHERE
    source IN (
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
    )
    AND lts IS NULL
    AND bicycle_category = 'crossing';

UPDATE
    osm_road_edges
SET
    lts = 3
WHERE
    source IN (
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
    )
    AND lts IS NULL
    AND bicycle_category = 'crossing';

UPDATE
    osm_road_edges
SET
    lts = 4
WHERE
    source IN (
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
    )
    AND lts IS NULL
    AND bicycle_category = 'crossing';

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
        AND cycling_allowed IS TRUE;

ASSERT lts_missing = 0,
'Cycling edges missing LTS value';

END $$;

DO $$
DECLARE
    lts_error INT;

BEGIN
    SELECT
        COUNT(*) INTO lts_error
    FROM
        osm_road_edges
    WHERE
        lts IS NOT NULL
        AND (
            car_traffic IS FALSE
            AND cycling_allowed IS FALSE
        );

ASSERT lts_error = 0,
'Edges with surplus LTS value';

END $$;

DROP VIEW IF EXISTS nodes_lts_1;

DROP VIEW IF EXISTS nodes_lts_2;

DROP VIEW IF EXISTS nodes_lts_3;

DROP VIEW IF EXISTS nodes_lts_4;

DROP VIEW IF EXISTS nodes_lts_5;