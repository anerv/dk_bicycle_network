ALTER TABLE
    nodes DROP COLUMN IF EXISTS lts;

-- INTERSECTION LTS 
ALTER TABLE
    nodes
ADD
    COLUMN lts INTEGER DEFAULT NULL;

CREATE VIEW nodes_lts_1 AS WITH nodes AS (
    SELECT
        source AS node
    FROM
        osm_road_edges
    WHERE
        lts = 1
    UNION
    SELECT
        target AS node
    FROM
        osm_road_edges
    WHERE
        lts = 1
)
SELECT
    DISTINCT node
FROM
    nodes;

CREATE VIEW nodes_lts_2 AS WITH nodes AS (
    SELECT
        source AS node
    FROM
        osm_road_edges
    WHERE
        lts = 2
    UNION
    SELECT
        target AS node
    FROM
        osm_road_edges
    WHERE
        lts = 2
)
SELECT
    DISTINCT node
FROM
    nodes;

CREATE VIEW nodes_lts_3 AS WITH nodes AS (
    SELECT
        source AS node
    FROM
        osm_road_edges
    WHERE
        lts = 3
    UNION
    SELECT
        target AS node
    FROM
        osm_road_edges
    WHERE
        lts = 3
)
SELECT
    DISTINCT node
FROM
    nodes;

CREATE VIEW nodes_lts_4 AS WITH nodes AS (
    SELECT
        source AS node
    FROM
        osm_road_edges
    WHERE
        lts = 4
    UNION
    SELECT
        target AS node
    FROM
        osm_road_edges
    WHERE
        lts = 4
)
SELECT
    DISTINCT node
FROM
    nodes;

CREATE VIEW nodes_lts_0 AS WITH nodes AS (
    SELECT
        source AS node
    FROM
        osm_road_edges
    WHERE
        lts = 0
    UNION
    SELECT
        target AS node
    FROM
        osm_road_edges
    WHERE
        lts = 0
)
SELECT
    DISTINCT node
FROM
    nodes;

CREATE VIEW nodes_lts_999 AS WITH nodes AS (
    SELECT
        source AS node
    FROM
        osm_road_edges
    WHERE
        lts = 999
    UNION
    SELECT
        target AS node
    FROM
        osm_road_edges
    WHERE
        lts = 999
)
SELECT
    DISTINCT node
FROM
    nodes;

UPDATE
    nodes
SET
    lts = CASE
        WHEN id IN (
            SELECT
                node
            FROM
                nodes_lts_4
        ) THEN 4
        WHEN id IN (
            SELECT
                node
            FROM
                nodes_lts_3
        ) THEN 3
        WHEN id IN (
            SELECT
                node
            FROM
                nodes_lts_2
        ) THEN 2
        WHEN id IN (
            SELECT
                node
            FROM
                nodes_lts_1
        ) THEN 1
        WHEN id IN (
            SELECT
                node
            FROM
                nodes_lts_0
        ) THEN 0
        WHEN id IN (
            SELECT
                node
            FROM
                nodes_lts_999
        ) THEN 999
    END;