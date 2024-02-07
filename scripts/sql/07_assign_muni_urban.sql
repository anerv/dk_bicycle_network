DROP INDEX IF EXISTS muni_geom_idx;

DROP INDEX IF EXISTS urban_geom_idx;

CREATE INDEX muni_geom_idx ON muni_boundaries USING GIST (geometry);

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

-- Assign urban part 1
CREATE MATERIALIZED VIEW urban_buffer AS
SELECT
    area_class,
    ST_buffer(geometry, 20) geometry
FROM
    urban_zones;

CREATE INDEX urban_buffer_geom_idx ON urban_buffer USING GIST (geometry);

UPDATE
    osm_road_edges o
SET
    urban = u.area_class
FROM
    urban_buffer u
WHERE
    ST_Within(o.geometry, u.geometry);

-- Assign urban part 2
CREATE MATERIALIZED VIEW area_buffer AS
SELECT
    area_class,
    ST_buffer(geometry, 20) geometry
FROM
    building_areas;

CREATE INDEX area_buffer_geom_idx ON area_buffer USING GIST (geometry);

UPDATE
    osm_road_edges o
SET
    urban = ab.area_class
FROM
    area_buffer ab
WHERE
    ST_Within(o.geometry, ab.geometry);

DROP MATERIALIZED VIEW IF EXISTS urban_buffer;

DROP MATERIALIZED VIEW IF EXISTS area_buffer;