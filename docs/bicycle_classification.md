# Explanation of classification of bicycle infrastructure

Below is a brief explanation of the most important columns used in the bicycle classification of OSM data.

## bicycle_category

cycle_living_street / cycleway / 'cycleway_shared' / cycletrack / cyclelane / crossing / shared_track / shared_lane / shared_busway

## along_street

Specifies whether bicycle infrastructure runs along a street with motorized traffic or not. Primarily intended to capture protected bicycle tracks mapped as separate cycleways.

True/False.

## protected

Specifies whether bicycle infrastructure is physically separated from motorized traffic or not.

True/False.

## cycleway_segregated

Specifies whether cyclists and pedestrians are segregated (True) or not (False) for infrastructure where both cyclists and pedestrians are allowed. Used for e.g. edges mapped as 'pedestrian', 'living_street', 'footway', 'bridleway', or 'path',

True/False.

## bicycle_class

Value from 1-3. Specifies the protection level of bicycle infrastructure. 1 = protected (e.g. tracks), 2 = unprotected (e.g. lanes), 3 = mixed traffic (e.g. bicycle streets).

## bicycle_infrastructure

True if edge has dedicated bicycle infrastructure mapped in OSM (including shared lanes, bicycle streets etc.).

True/False.

## bicycle_infrastructure_final

True if edge has dedicated bicycle infrastructure mapped in OSM OR GeoDanmark, or if the edge otherwise has been classified as bicycle infrastructure based on placement with other mapped bicycle infrastructure.

True/False.

## geodk_category

The original road category of matched GeoDanmark bicycle infrastructure.

## cycling_allowed

Whether cycling is allowed or not based on the bicycle tag and the type of edge ('highway' value).

True/False.

## car_traffic

Whether car traffic is allowed. False if access is no (even though it is a car road).

True/False.

## lts

Values 1,2,3,4,999,0.
Specifies the level of traffic stress.

## urban

The degree of urbanization for the location of each edge.

## matched

Whether an edge was matched to a corresponding GeoDanmark edge or not.

True/False.
