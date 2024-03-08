-- Get info on surface and road category from geodk data 
--first, unpack arrays into temp columns
ALTER TABLE
    osm_road_edges DROP COLUMN IF EXISTS category_temp,
    DROP COLUMN IF EXISTS surface_temp;

ALTER TABLE
    osm_road_edges
ADD
    COLUMN category_temp VARCHAR,
ADD
    COLUMN surface_temp VARCHAR;

UPDATE
    osm_road_edges
SET
    surface_temp =(
        SELECT
            ARRAY(
                SELECT
                    unnest(geodk_surface :: text [ ])
                EXCEPT
                SELECT
                    NULL
            )
    )
WHERE
    matched IS TRUE;

UPDATE
    osm_road_edges
SET
    category_temp =(
        SELECT
            ARRAY(
                SELECT
                    unnest(geodk_category :: text [ ])
                EXCEPT
                SELECT
                    NULL
            )
    )
WHERE
    matched IS TRUE;

UPDATE
    osm_road_edges
SET
    category_temp = CASE
        WHEN category_temp = '{"Cykelsti langs vej"}' THEN 'Cykelsti langs vej'
        WHEN category_temp = '{"Cykelbane langs vej"}' THEN 'Cykelbane langs vej'
        WHEN category_temp = '{"Cykelbane langs vej","Cykelsti langs vej"}' THEN 'Cykelsti langs vej'
        WHEN category_temp = '{"Cykelsti langs vej","Cykelbane langs vej"}' THEN 'Cykelsti langs vej'
    END
WHERE
    matched = TRUE;

UPDATE
    osm_road_edges
SET
    surface_temp = CASE
        WHEN surface_temp = '{Befæstet}' THEN 'Befæstet'
        WHEN surface_temp = '{Ubefæstet}' THEN 'Ubefæstet'
        WHEN surface_temp = '{Ukendt}' THEN 'Ukendt'
        WHEN surface_temp = '{Befæstet,Ubefæstet}' THEN 'Befæstet'
        WHEN surface_temp = '{Ubefæstet,Befæstet}' THEN 'Befæstet'
    END
WHERE
    matched = TRUE;

DO $$
DECLARE
    category_temp_null INT;

BEGIN
    SELECT
        COUNT(*) INTO category_temp_null
    FROM
        osm_road_edges
    WHERE
        geodk_category IS NOT NULL
        AND category_temp IS NULL;

ASSERT category_temp_null = 0,
'Issue with classification';

END $$;

DO $$
DECLARE
    surface_temp_null INT;

BEGIN
    SELECT
        COUNT(*) INTO surface_temp_null
    FROM
        osm_road_edges
    WHERE
        geodk_surface IS NOT NULL
        AND surface_temp IS NULL;

ASSERT surface_temp_null = 0,
'Issue with classification';

END $$;

UPDATE
    osm_road_edges
SET
    geodk_category = category_temp
WHERE
    matched = TRUE;

UPDATE
    osm_road_edges
SET
    geodk_surface = surface_temp
WHERE
    matched = TRUE;

ALTER TABLE
    osm_road_edges DROP COLUMN category_temp,
    DROP COLUMN surface_temp;

CREATE VIEW matching_geodk_osm._cykelsti_nodes AS (
    SELECT
        source AS node
    FROM
        osm_road_edges
    WHERE
        matched IS TRUE
        AND geodk_category = 'Cykelsti langs vej'
    UNION
    SELECT
        target AS node
    FROM
        osm_road_edges
    WHERE
        matched IS TRUE
        AND geodk_category = 'Cykelsti langs vej'
);

UPDATE
    osm_road_edges
SET
    geodk_category = 'Cykelsti langs vej'
WHERE
    source IN (
        SELECT
            node
        FROM
            matching_geodk_osm._cykelsti_nodes
    )
    AND target IN (
        SELECT
            node
        FROM
            matching_geodk_osm._cykelsti_nodes
    )
    AND matched IS TRUE
    AND geodk_category IS NULL;

CREATE VIEW matching_geodk_osm._cykelbane_nodes AS (
    SELECT
        source AS node
    FROM
        osm_road_edges
    WHERE
        matched IS TRUE
        AND geodk_category = 'Cykelbane langs vej'
    UNION
    SELECT
        target AS node
    FROM
        osm_road_edges
    WHERE
        matched IS TRUE
        AND geodk_category = 'Cykelbane langs vej'
);

UPDATE
    osm_road_edges
SET
    geodk_category = 'Cykelbane langs vej'
WHERE
    source IN (
        SELECT
            node
        FROM
            matching_geodk_osm._cykelbane_nodes
    )
    AND target IN (
        SELECT
            node
        FROM
            matching_geodk_osm._cykelbane_nodes
    )
    AND matched IS TRUE
    AND geodk_category IS NULL;

CREATE VIEW matching_geodk_osm._befaestet_nodes AS (
    SELECT
        source AS node
    FROM
        osm_road_edges
    WHERE
        matched IS TRUE
        AND geodk_surface = 'Befæstet'
    UNION
    SELECT
        target AS node
    FROM
        osm_road_edges
    WHERE
        matched IS TRUE
        AND geodk_surface = 'Befæstet'
);

UPDATE
    osm_road_edges
SET
    geodk_surface = 'Befæstet'
WHERE
    source IN (
        SELECT
            node
        FROM
            matching_geodk_osm._befaestet_nodes
    )
    AND target IN (
        SELECT
            node
        FROM
            matching_geodk_osm._befaestet_nodes
    )
    AND matched IS TRUE
    AND geodk_surface IS NULL;

CREATE VIEW matching_geodk_osm._ubefaestet_nodes AS (
    SELECT
        source AS node
    FROM
        osm_road_edges
    WHERE
        matched IS TRUE
        AND geodk_surface = 'Ubefæstet'
    UNION
    SELECT
        target AS node
    FROM
        osm_road_edges
    WHERE
        matched IS TRUE
        AND geodk_surface = 'Ubefæstet'
);

UPDATE
    osm_road_edges
SET
    geodk_surface = 'Ubefæstet'
WHERE
    source IN (
        SELECT
            node
        FROM
            matching_geodk_osm._ubefaestet_nodes
    )
    AND target IN (
        SELECT
            node
        FROM
            matching_geodk_osm._ubefaestet_nodes
    )
    AND matched IS TRUE
    AND geodk_surface IS NULL;

UPDATE
    osm_road_edges
SET
    geodk_surface = 'Befæstet'
WHERE
    (
        source IN (
            SELECT
                node
            FROM
                matching_geodk_osm._befaestet_nodes
        )
        OR target IN (
            SELECT
                node
            FROM
                matching_geodk_osm._befaestet_nodes
        )
    )
    AND matched IS TRUE
    AND geodk_surface IS NULL;

UPDATE
    osm_road_edges
SET
    geodk_category = 'Cykelbane langs vej'
WHERE
    (
        source IN (
            SELECT
                node
            FROM
                matching_geodk_osm._cykelbane_nodes
        )
        OR target IN (
            SELECT
                node
            FROM
                matching_geodk_osm._cykelbane_nodes
        )
    )
    AND matched IS TRUE
    AND geodk_category IS NULL;

UPDATE
    osm_road_edges
SET
    geodk_category = 'Cykelsti langs vej'
WHERE
    (
        source IN (
            SELECT
                node
            FROM
                matching_geodk_osm._cykelsti_nodes
        )
        OR target IN (
            SELECT
                node
            FROM
                matching_geodk_osm._cykelsti_nodes
        )
    )
    AND matched IS TRUE
    AND geodk_category IS NULL;

DO $$
DECLARE
    matched_no_class INT;

BEGIN
    SELECT
        COUNT(*) INTO matched_no_class
    FROM
        osm_road_edges
    WHERE
        geodk_category IS NULL
        AND matched IS TRUE;

ASSERT matched_no_class = 0,
'Issue with category of matched edges';

END $$;

DO $$
DECLARE
    matched_no_surface INT;

BEGIN
    SELECT
        COUNT(*) INTO matched_no_surface
    FROM
        osm_road_edges
    WHERE
        geodk_surface IS NULL
        AND matched IS TRUE;

ASSERT matched_no_surface = 0,
'Issue with surface of matched edges';

END $$;

DO $$
DECLARE
    matched_error_class INT;

BEGIN
    SELECT
        COUNT(*) INTO matched_error_class
    FROM
        osm_road_edges
    WHERE
        geodk_category IS NOT NULL
        AND matched IS FALSE;

ASSERT matched_error_class = 0,
'Issue with category of matched edges';

END $$;

DO $$
DECLARE
    matched_error_surface INT;

BEGIN
    SELECT
        COUNT(*) INTO matched_error_surface
    FROM
        osm_road_edges
    WHERE
        geodk_surface IS NOT NULL
        AND matched IS FALSE;

ASSERT matched_error_surface = 0,
'Issue with surface of matched edges';

END $$;