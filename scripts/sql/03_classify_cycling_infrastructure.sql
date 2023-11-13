-- Identify bicycle infrastructure
ALTER TABLE
    osm_roads
ADD
    COLUMN bicycle_infrastructure BOOLEAN NOT NULL DEFAULT FALSE;

UPDATE
    osm_roads
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
    osm_roads
SET
    bicycle_infrastructure = FALSE
WHERE
    bicycle IN ('no', 'dismount');

-- Classify bicycle infra as either protected or unprotected
ALTER TABLE
    osm_roads
ADD
    COLUMN bicycle_protected BOOLEAN;

UPDATE
    osm_roads
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
    osm_roads
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
do $ $ declare non_classified_bicycle_infra INT;

begin
select
    count(*) into non_classified_bicycle_infra
FROM
    osm_roads
WHERE
    bicycle_infrastructure is TRUE
    and bicycle_protected IS NULL;

assert non_classified_bicycle_infra = 0,
'Found bicycle infra with no protection level';

end $ $;