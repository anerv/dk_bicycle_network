-- INTERSECTION LTS? (Identify unmarked intersections where a LTS XX crosses a road with a higher LTS)
CREATE VIEW nodes_lts_1 AS (
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
);

CREATE VIEW nodes_lts_2 AS (
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
);

CREATE VIEW nodes_lts_3 AS (
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
);

CREATE VIEW nodes_lts_4 AS (
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
);

CREATE VIEW nodes_lts_5 AS (
    SELECT
        source AS node
    FROM
        osm_road_edges
    WHERE
        lts = 5
    UNION
    SELECT
        target AS node
    FROM
        osm_road_edges
    WHERE
        lts = 5
);

ALTER TABLE
    nodes
ADD
    COLUMN lts INTEGER DEFAULT NULL;

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
                nodes_lts_999
        ) THEN 999
    END;

-- UPDATE
--     nodes
-- SET
--     lts = 1
-- WHERE
--     id IN (
--         SELECT
--             node
--         FROM
--             nodes_lts_1
--     );
-- UPDATE
--     nodes
-- SET
--     lts = 2
-- WHERE
--     id IN (
--         SELECT
--             node
--         FROM
--             nodes_lts_2
--     );
-- UPDATE
--     nodes
-- SET
--     lts = 3
-- WHERE
--     id IN (
--         SELECT
--             node
--         FROM
--             nodes_lts_3
--     );
-- UPDATE
--     nodes
-- SET
--     lts = 4
-- WHERE
--     id IN (
--         SELECT
--             node
--         FROM
--             nodes_lts_4
--     );
-- UPDATE
--     nodes
-- SET
--     lts = 5
-- WHERE
--     id IN (
--         SELECT
--             node
--         FROM
--             nodes_lts_5
--     );