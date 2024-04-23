DROP INDEX IF EXISTS muni_geom_idx;

DROP MATERIALIZED VIEW IF EXISTS urban_buffer;

DROP MATERIALIZED VIEW IF EXISTS summerhouse_buffer;

DROP MATERIALIZED VIEW IF EXISTS industrial_buffer;

DROP TABLE IF EXISTS urban_areas;

DROP TABLE IF EXISTS summerhouse_areas;

DROP TABLE IF EXISTS industrial_areas;

DROP TABLE IF EXISTS urban_areas_dissolved;

DROP TABLE IF EXISTS summerhouse_areas_dissolved;

DROP TABLE IF EXISTS industrial_areas_dissolved;

CREATE INDEX muni_geom_idx ON muni_boundaries USING GIST (geometry);

ALTER TABLE
    osm_road_edges DROP COLUMN IF EXISTS municipality,
    DROP COLUMN IF EXISTS urban;

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

-- FIND EDGES WITH NO MUNICIPALITY AND WHICH ARE BRIDGES OR TUNNELS (other coastal/border edges are not included)
WITH no_muni_edges AS (
    SELECT
        muni_edges.id,
        muni_edges.navn,
        muni_edges.dist,
        o.geometry
    FROM
        osm_road_edges o
        CROSS JOIN LATERAL (
            SELECT
                o.id,
                muni.navn,
                o.geometry < -> muni.geometry AS dist
            FROM
                muni_boundaries muni
            WHERE
                o.municipality IS NULL
                AND (
                    (
                        o.bridge IN (
                            'yes',
                            'movable',
                            'viaduct',
                            'covered',
                            'cantilever',
                            'trestle',
                            'simple_brunnel',
                            'low_water_crossing'
                        )
                    )
                    OR (
                        (
                            o.tunnel IN ('yes', 'passage')
                        )
                    )
                )
                AND ST_DWithin(o.geometry, muni.geometry, 500)
            ORDER BY
                dist
            LIMIT
                1
        ) muni_edges
)
UPDATE
    osm_road_edges o
SET
    municipality = no_muni_edges.navn
FROM
    no_muni_edges
WHERE
    o.id = no_muni_edges.id
    AND o.municipality IS NULL;

CREATE TABLE urban_areas AS
SELECT
    area_class,
    (ST_Dump(geometry)) .geom AS geometry
FROM
    urban_zones
WHERE
    area_class = 'urban'
UNION
SELECT
    area_class,
    (ST_Dump(geometry)) .geom AS geometry
FROM
    building_areas
WHERE
    area_class = 'urban';

CREATE TABLE summerhouse_areas AS
SELECT
    area_class,
    (ST_Dump(geometry)) .geom AS geometry
FROM
    urban_zones
WHERE
    area_class = 'summerhouse'
UNION
SELECT
    area_class,
    (ST_Dump(geometry)) .geom AS geometry
FROM
    building_areas
WHERE
    area_class = 'summerhouse';

CREATE TABLE industrial_areas AS
SELECT
    area_class,
    (ST_Dump(geometry)) .geom AS geometry
FROM
    urban_zones
WHERE
    area_class = 'industrial'
UNION
SELECT
    area_class,
    (ST_Dump(geometry)) .geom AS geometry
FROM
    building_areas
WHERE
    area_class = 'industrial';

-- Assign urban land use class
CREATE TABLE urban_areas_dissolved AS
SELECT
    --area_class,
    ST_MakePolygon(
        ST_ExteriorRing(
            (ST_Dump(ST_Union(ST_Buffer(geometry, 1)))) .geom
        )
    ) AS geometry
FROM
    urban_areas;

CREATE MATERIALIZED VIEW urban_buffer AS
SELECT
    --area_class,
    ST_buffer(ST_Simplify(geometry, 10), 20) geometry
FROM
    urban_areas_dissolved;

CREATE INDEX urban_buffer_geom_idx ON urban_buffer USING GIST (geometry);

-- Assign summerhouse land use class
CREATE TABLE summerhouse_areas_dissolved AS
SELECT
    --area_class,
    ST_MakePolygon(
        ST_ExteriorRing(
            (ST_Dump(ST_Union(ST_Buffer(geometry, 1)))) .geom
        )
    ) AS geometry
FROM
    summerhouse_areas;

CREATE MATERIALIZED VIEW summerhouse_buffer AS
SELECT
    --area_class,
    ST_buffer(ST_Simplify(geometry, 10), 20) geometry
FROM
    summerhouse_areas_dissolved;

CREATE INDEX summerhouse_buffer_geom_idx ON summerhouse_buffer USING GIST (geometry);

-- Assign industrial land use class
CREATE TABLE industrial_areas_dissolved AS
SELECT
    --area_class,
    ST_MakePolygon(
        ST_ExteriorRing(
            (ST_Dump(ST_Union(ST_Buffer(geometry, 1)))) .geom
        )
    ) AS geometry
FROM
    industrial_areas;

CREATE MATERIALIZED VIEW industrial_buffer AS
SELECT
    --area_class,
    ST_buffer(ST_Simplify(geometry, 10), 20) geometry
FROM
    industrial_areas_dissolved;

CREATE INDEX indu_buffer_geom_idx ON industrial_buffer USING GIST (geometry);

UPDATE
    osm_road_edges o
SET
    urban = 'industrial'
FROM
    industrial_buffer u
WHERE
    ST_Within(o.geometry, u.geometry);

UPDATE
    osm_road_edges o
SET
    urban = 'summerhouse'
FROM
    summerhouse_buffer u
WHERE
    ST_Within(o.geometry, u.geometry);

UPDATE
    osm_road_edges o
SET
    urban = 'urban'
FROM
    urban_buffer u
WHERE
    ST_Within(o.geometry, u.geometry);

DROP MATERIALIZED VIEW IF EXISTS urban_buffer;

DROP MATERIALIZED VIEW IF EXISTS summerhouse_buffer;

DROP MATERIALIZED VIEW IF EXISTS industrial_buffer;

DROP TABLE IF EXISTS urban_areas;

DROP TABLE IF EXISTS summerhouse_areas;

DROP TABLE IF EXISTS industrial_areas;

DROP TABLE IF EXISTS urban_areas_dissolved;

DROP TABLE IF EXISTS summerhouse_areas_dissolved;

DROP TABLE IF EXISTS industrial_areas_dissolved;