DROP INDEX IF EXISTS muni_geom_idx;

DROP INDEX IF EXISTS urban_geom_idx;

CREATE INDEX muni_geom_idx ON muni_boundaries USING GIST (geometry);

--CREATE INDEX urban_zones_geom_idx ON urban_zones USING GIST (geometry);
ALTER TABLE
    osm_road_edges
ADD
    COLUMN municipality VARCHAR DEFAULT NULL,
ADD
    COLUMN urban VARCHAR DEFAULT NULL,
ADD
    COLUMN urban_zone VARCHAR DEFAULT NULL;

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
CREATE MATERIALIZED VIEW urban_buffer AS
SELECT
    ZONE,
    ST_buffer(geometry, 20) geometry
FROM
    urban_zones;

CREATE INDEX urban_buffer_geom_idx ON urban_buffer USING GIST (geometry);

UPDATE
    osm_road_edges o
SET
    urban = u.zone
FROM
    urban_buffer u
WHERE
    ST_Within(o.geometry, u.geometry);

UPDATE
    osm_road_edges
SET
    urban_zone = 'urban'
WHERE
    urban = 1;

UPDATE
    osm_road_edges
SET
    urban_zone = 'summerhouse'
WHERE
    urban = 3;