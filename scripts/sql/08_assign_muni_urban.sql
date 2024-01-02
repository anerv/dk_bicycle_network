DROP INDEX IF EXISTS muni_geom_idx;

DROP INDEX IF EXISTS urban_geom_idx;

CREATE INDEX muni_geom_idx ON muni_boundaries USING GIST (geometry);

CREATE INDEX urban_geom_idx ON urban_polygons_8 USING GIST (geometry);

ALTER TABLE
    osm_road_edges
ADD
    COLUMN municipality VARCHAR DEFAULT NULL,
ADD
    COLUMN urban VARCHAR DEFAULT NULL;

-- Assign municipality to network
UPDATE
    osm_road_edges o
SET
    municipality = m.navn
FROM
    muni_boundaries m
WHERE
    ST_Intersects(o.geometry, m.geometry);

UPDATE
    osm_road_edges o
SET
    municipality = m.navn
FROM
    muni_boundaries m
WHERE
    o.municipality IS NULL
    AND ST_Intersects(o.geometry, ST_Buffer(m.geometry, 100));

-- Assign urban
WITH urban_selection AS (
    SELECT
        *
    FROM
        urban_polygons_8
    WHERE
        urban_code > 10
)
UPDATE
    osm_road_edges o
SET
    urban = u.urban
FROM
    urban_selection u
WHERE
    ST_Within(o.geometry, u.geometry);

WITH urban_selection AS (
    SELECT
        *
    FROM
        urban_polygons_8
    WHERE
        urban_code > 10
)
UPDATE
    osm_road_edges o
SET
    urban = u.urban
FROM
    urban_selection u
WHERE
    o.urban IS NULL
    AND ST_Within(ST_Centroid(o.geometry), u.geometry);

-- moved to py file
-- WITH urban_selection AS (
--     SELECT
--         *
--     FROM
--         urban_polygons_8
--     WHERE
--         urban_code > 10
-- )
-- UPDATE
--     osm_road_edges o
-- SET
--     urban = (
--         SELECT
--             urban
--         FROM
--             urban_selection u
--         ORDER BY
--             u.geometry < -> o.geometry
--         LIMIT
--             1
--     )
-- WHERE
--     o.urban IS NULL;