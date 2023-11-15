CREATE INDEX muni_geom_idx ON muni_boundaries USING GIST (geometry);


CREATE INDEX urban_geom_idx ON urban_polygons_8 USING GIST (geometry);


-- Assign municipality to network
ALTER TABLE
    osm_roads
ADD
    COLUMN municipality VARCHAR DEFAULT NULL;


UPDATE
    osm_roads o
SET
    municipality = m.navn
FROM
    muni_boundaries m
WHERE
    ST_Intersects(o.geometry, m.geometry);


-- Assign urban type to network
ALTER TABLE
    osm_roads
ADD
    COLUMN urban VARCHAR DEFAULT NULL;


WITH urban_selection AS (
    SELECT
        *
    FROM
        urban_polygons_8
    WHERE
        urban_code > 10
)
UPDATE
    osm_roads o
SET
    urban = u.urban
FROM
    urban_selection u
WHERE
    ST_Within(o.geometry, u.geometry);


WITH urban_polys AS (
    SELECT
        *
    FROM
        urban_polygons_8
)
SELECT
    u.urban,
    ST_Distance(o.geometry, u.geometry) AS dist_m
FROM
    osm_roads o
    CROSS JOIN LATERAL (
        SELECT
            u.geometry,
            u.hex_id_8,
            u.urban
        FROM
            urban_polys u
        ORDER BY
            o.geometry < -> u.geometry
        LIMIT
            1
    ) z;


CREATE TABLE unmatched_osm_road AS WITH urban_polys AS (
    SELECT
        *
    FROM
        urban_polygons_8
    WHERE
        urban_code > 10
),
osm_unmatched AS (
    SELECT
        *
    FROM
        osm_roads
    WHERE
        urban IS NULL
)
SELECT
    b.osm_id AS osm_id,
    ST_Distance(a.geometry, ST_Centroid(b.geometry)) AS dist_m,
    a.hex_id_8,
    a.urban
FROM
    osm_roads b
    CROSS JOIN LATERAL (
        SELECT
            a.geometry,
            a.hex_id_8,
            a.urban
        FROM
            urban_polys a
        ORDER BY
            ST_Centroid(b.geometry) < -> a.geometry
        LIMIT
            1
    ) a;


UPDATE
    osm_roads
SET
    urban = u.urban
FROM
    unmatched_osm_roads u
WHERE
    osm_roads.osm_id = u.osm_id;