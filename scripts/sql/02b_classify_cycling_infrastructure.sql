-- Identify bicycle infrastructure
ALTER TABLE
    osm_road_edges
ADD
    COLUMN bicycle_infrastructure BOOLEAN NOT NULL DEFAULT FALSE;

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
        highway = 'track'
        AND bicycle IN ('designated', 'yes')
    )
    OR (
        highway = 'path'
        AND bicycle IN ('designated', 'yes')
    )
    OR cycleway IN (
        'track',
        'opposite_track',
        'share_sidewalk',
        'share_busway',
        'opposite_lane',
        'crossing',
        'lane'
    )
    OR "cycleway:left" IN (
        'track',
        'opposite_track',
        'share_sidewalk',
        'share_busway',
        'opposite_lane',
        'crossing',
        'lane'
    )
    OR "cycleway:right" IN (
        'track',
        'opposite_track',
        'share_sidewalk',
        'share_busway',
        'opposite_lane',
        'crossing',
        'lane'
    )
    OR "cycleway:both" IN (
        'track',
        'opposite_track',
        'share_sidewalk',
        'share_busway',
        'opposite_lane',
        'crossing',
        'lane'
    );

UPDATE
    osm_road_edges
SET
    bicycle_infrastructure = FALSE
WHERE
    bicycle IN ('no', 'dismount');

-- Classify bicycle infra as either protected or unprotected
ALTER TABLE
    osm_road_edges
ADD
    COLUMN bicycle_protected BOOLEAN;

UPDATE
    osm_road_edges
SET
    bicycle_protected = TRUE
WHERE
    highway = 'cycleway'
    OR (
        highway = 'track'
        AND bicycle IN ('designated', 'yes')
    )
    OR (
        highway = 'path'
        AND bicycle IN ('designated', 'yes')
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
        'opposite_lane',
        'crossing',
        'lane'
    )
    OR "cycleway:left" IN (
        'share_busway',
        'opposite_lane',
        'crossing',
        'lane'
    )
    OR "cycleway:right" IN (
        'share_busway',
        'opposite_lane',
        'crossing',
        'lane'
    )
    OR "cycleway:both" IN (
        'share_busway',
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
        count(*) INTO non_classified_bicycle_infra
    FROM
        osm_road_edges
    WHERE
        bicycle_infrastructure IS TRUE
        AND bicycle_protected IS NULL;

ASSERT non_classified_bicycle_infra = 0,
'Found bicycle infra with no protection level';

END $$;