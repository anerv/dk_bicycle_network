-- Identify bicycle infrastructure
ALTER TABLE
    osm_road_edges
ADD
    COLUMN bicycle_infrastructure BOOLEAN NOT NULL DEFAULT FALSE,
ADD
    COLUMN bicycle_protected BOOLEAN DEFAULT NULL;

UPDATE
    osm_road_edges
SET
    bicycle_infrastructure = TRUE
WHERE
    highway = 'cycleway'
    OR highway = 'living_street'
    OR bicycle_road = 'yes'
    OR cyclestreet = 'yes'
    OR (
        highway IN (
            'path',
            'footway',
            'bridleway',
            'pedestrian'
        )
        AND bicycle IN (
            'yes',
            'permissive',
            'ok',
            'allowed',
            'designated'
        )
    )
    OR cycleway IN (
        'track',
        'opposite_track',
        'share_sidewalk',
        'share_busway',
        'opposite_share_busway',
        'shared_lane',
        'opposite_lane',
        'crossing',
        'lane'
    )
    OR "cycleway:left" IN (
        'track',
        'opposite_track',
        'share_sidewalk',
        'share_busway',
        'opposite_share_busway',
        'shared_lane',
        'opposite_lane',
        'crossing',
        'lane'
    )
    OR "cycleway:right" IN (
        'track',
        'opposite_track',
        'share_sidewalk',
        'share_busway',
        'opposite_share_busway',
        'shared_lane',
        'opposite_lane',
        'crossing',
        'lane'
    )
    OR "cycleway:both" IN (
        'track',
        'opposite_track',
        'share_sidewalk',
        'share_busway',
        'opposite_share_busway',
        'shared_lane',
        'opposite_lane',
        'crossing',
        'lane'
    );

UPDATE
    osm_road_edges
SET
    bicycle_infrastructure = FALSE
WHERE
    bicycle IN ('no', 'use_sidepath');

-- Don't include infrastructure with non-bikeable surface
UPDATE
    osm_road_edges
SET
    bicycle_infrastructure = FALSE
WHERE
    highway IN ('path', 'footway', 'bridleway')
    AND (
        surface IN (
            'artificial_turf',
            'clay',
            'dirt',
            'dirt/sand',
            'driving_plates',
            'earth',
            'grass',
            'grass_paver;sand',
            'ground',
            'mixed',
            'mud',
            'rock',
            'rocks',
            'sand',
            'sas',
            'stepping_stones',
            'unhewn_cobblestone',
            'woodchips',
            'yes'
        )
        OR "cycleway:surface" IN (
            'artificial_turf',
            'clay',
            'dirt',
            'dirt/sand',
            'driving_plates',
            'earth',
            'grass',
            'grass_paver;sand',
            'ground',
            'mixed',
            'mud',
            'rock',
            'rocks',
            'sand',
            'sas',
            'stepping_stones',
            'unhewn_cobblestone',
            'woodchips',
            'yes'
        )
    )
    OR tracktype IN ('grade4', 'grade5');

-- don't include paths etc where cycling is not allowed
UPDATE
    osm_road_edges
SET
    bicycle_infrastructure = FALSE
WHERE
    bicycle IN ('no', 'dismount')
    AND highway IN ('path', 'living_street');

-- Classify bicycle infra as either protected or unprotected
UPDATE
    osm_road_edges
SET
    bicycle_protected = TRUE
WHERE
    highway = 'cycleway'
    OR (
        highway IN (
            'path',
            'footway',
            'bridleway',
            'pedestrian'
        )
        AND bicycle IN (
            'yes',
            'permissive',
            'ok',
            'allowed',
            'designated'
        )
        AND bicycle_infrastructure IS TRUE
    )
    OR cycleway IN ('track', 'opposite_track', 'share_sidewalk')
    OR "cycleway:left" IN ('track', 'opposite_track', 'share_sidewalk')
    OR "cycleway:right" IN ('track', 'opposite_track', 'share_sidewalk')
    OR "cycleway:both" IN ('track', 'opposite_track', 'share_sidewalk');

UPDATE
    osm_road_edges
SET
    bicycle_protected = FALSE
WHERE
    highway = 'living_street'
    OR bicycle_road = 'yes'
    OR cyclestreet = 'yes'
    OR cycleway IN (
        'share_busway',
        'opposite_share_busway',
        'opposite_lane',
        'shared_lane',
        'crossing',
        'lane'
    )
    OR "cycleway:left" IN (
        'share_busway',
        'opposite_share_busway',
        'shared_lane',
        'opposite_lane',
        'crossing',
        'lane'
    )
    OR "cycleway:right" IN (
        'share_busway',
        'opposite_share_busway',
        'shared_lane',
        'opposite_lane',
        'crossing',
        'lane'
    )
    OR "cycleway:both" IN (
        'share_busway',
        'opposite_share_busway',
        'shared_lane',
        'opposite_lane',
        'crossing',
        'lane'
    );

-- Check that all bicycle infra is either protected true or false
DO $$
DECLARE
    non_classified_bicycle_infra INT;

BEGIN
    SELECT
        COUNT(*) INTO non_classified_bicycle_infra
    FROM
        osm_road_edges
    WHERE
        bicycle_infrastructure IS TRUE
        AND bicycle_protected IS NULL;

ASSERT non_classified_bicycle_infra = 0,
'Found bicycle infra with no protection level';

END $$;