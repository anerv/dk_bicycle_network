DROP TABLE IF EXISTS geodk_bike CASCADE;

CREATE TABLE geodk_bike AS
SELECT
    vejkode,
    objectid,
    status,
    geom AS geometry,
    kommunekode,
    trafikart,
    niveau,
    overflade,
    vejmidtetype,
    vejkategori
FROM
    vejmidte
WHERE
    vejkategori IN ('Cykelsti langs vej', 'Cykelbane langs vej')
    AND status IN ('Anlagt', 'Under anlæg');

ALTER TABLE
    geodk_bike
ALTER COLUMN
    geometry TYPE Geometry(LineString, 25832) USING ST_Transform(geometry, 25832);

DROP TABLE IF EXISTS vejmidte;