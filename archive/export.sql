DROP TABLE IF EXISTS external_export_edges;

DROP TABLE IF EXISTS external_export_nodes;

CREATE TABLE external_export_edges AS (
    SELECT
        *
    FROM
        osm_edges_export
    WHERE
        municipality IN (
            -- 'Albertslund',
            -- 'Allerød',
            -- 'Ballerup',
            -- 'Brøndby',
            -- 'Dragør',
            -- 'Egedal',
            -- 'Fredensborg',
            'Frederiksberg',
            -- 'Frederikssund',
            -- 'Furesø',
            -- 'Gentofte',
            -- 'Gladsaxe',
            -- 'Glostrup',
            -- 'Greve',
            -- 'Gribskov',
            -- 'Halsnæs',
            -- 'Helsingør',
            -- 'Herlev',
            -- 'Hillerød',
            -- 'Hvidovre',
            -- 'Høje-Taastrup',
            -- 'Hørsholm',
            -- 'Ishøj',
            'København' --,
            -- 'Køge',
            -- 'Lyngby-Taarbæk',
            -- 'Roskilde',
            -- 'Rudersdal',
            -- 'Rødovre',
            -- 'Solrød',
            -- 'Tårnby',
            -- 'Vallensbæk'
        )
);

CREATE TABLE external_export_nodes AS (
    SELECT
        *
    FROM
        osm_nodes_export
    WHERE
        id IN (
            SELECT
                source AS node
            FROM
                external_export_edges
            UNION
            SELECT
                target AS node
            FROM
                external_export_edges
        )
);