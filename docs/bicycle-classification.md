# Classification of bicycle infrastructure

Below is a brief explanation of the most important columns used in the bicycle classification of OSM road network data.

## OSM road network edges

### bicycle_category

Indicates the type of bicycle infrastructure.

Type: Text.

Values: cycle_living_street, cycleway, cycleway_shared, cycletrack, cyclelane, crossing, shared_track, shared_lane, shared_busway

### along_street

Specifies whether bicycle infrastructure runs along a street with motorized traffic or not. Primarily intended to capture protected bicycle tracks mapped as separate cycleways.

Type: True/False.

### protected

Specifies whether bicycle infrastructure is physically separated from motorized traffic or not.

True/False.

### cycleway_segregated

Specifies whether cyclists and pedestrians are segregated (True) or not (False) for infrastructure where both cyclists and pedestrians are allowed. Used for e.g. edges mapped as 'pedestrian', 'living_street', 'footway', 'bridleway', or 'path',

True/False.

### bicycle_class

Value from 1-3. Specifies the protection level of bicycle infrastructure. 1 = protected (e.g. tracks), 2 = unprotected (e.g. lanes), 3 = mixed traffic (e.g. bicycle streets).

Type: Integer.

### bicycle_infrastructure

True if edge has dedicated bicycle infrastructure mapped in OSM (including shared lanes, bicycle streets etc.).

True/False.

### bicycle_infrastructure_final

True if edge has dedicated bicycle infrastructure mapped in OSM OR GeoDanmark, or if the edge otherwise has been classified as bicycle infrastructure based on placement with other mapped bicycle infrastructure.

Type: True/False.

### geodk_category

The original road category of matched GeoDanmark bicycle infrastructure.

Type: Text.

### cycling_allowed

Whether cycling is allowed or not based on the bicycle tag and the type of edge ('highway' value).

Type: True/False.

### car_traffic

Whether car traffic is allowed. False if access is no (even though it is a car road).

Type: True/False.

### lts

Values 1,2,3,4,999,0.

Specifies the level of traffic stress.

Type: Integer.

### urban

Indicates edges in urban zones or summerhouse zones.

Type: Text.

Values: 1 = urban, 3 = summerhouse.

### urban_zone

Verbose version of column urban.

Type: Text.

Values: 'urban','summerhouse.

### matched

Whether an edge was matched to a corresponding GeoDanmark edge or not.

Type: True/False.

### car_oneway

Indicates whether a road is one way or not for car traffic.

Type: True/False.

True means the segment only allows for traffic in one direction.

### bike_oneway

Indicates whether a road or path is one way or not for cyclists.

Type: True/False.

True means the segment only allows for traffic in one direction.

### bikeinfra_both_sides

Indicates whether there is bicycle infrastructure in both sides of a road or not.

Type: True/False.

True means the segment has dedicated bicycle infrastructure on both sides (and thus should count double when measuring the length of the bicycle network).

### all_access

False if a stretch has access restrictions (e.g. private or only for customers or residents).

Type: True/False.

### bicycle_infrastructure_separate

Indicates that a road has bicycle infrastructure, but that it has been mapped separately (i.e. with own geometries).
Useful for distinguishing between whether cycling is forbidded due to the road class or if it is because a bicycle track should be used.
OBS! This data is often missing.

Type: True/False.

## OSM road network nodes

### intersection_type

Indicates the regulation level of the intersection. See `06_classify_intersections.sql` for the exact definitions.

Type: Text.

Values: 'regulated', 'marked', 'unmarked'.

### node_degree

The node degree for each node, based on an undirected network.

### lts

Values 1,2,3,4,999,0.
Specifies the highest level of traffic stress of edges connected to that node.

Type: Integer.
