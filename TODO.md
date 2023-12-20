# TODO

- [X] New script for loading OSM to DB with osm2po
- [X] Transfer tags to edges
- [X] Adapt matching to use network edges

- [X] Mark all edges as matched/unmatched
- [ ] Add additional cycling info
- [ ] interpolate missing tags
- [X] script for identifying intersections in OSM
- [X] script for classifying intersections
- [X] script for indexing infra with muni
- [ ] script for indexing infra with H3??

- [ ] LTS CLASSIFICATION
- [ ] Close cycling gaps

- [ ] documentation
- [X] installation instructions

- [X] turn 01_create_db.sql into script/make sure in can be run from python
- [X] rename files names so it is clear what is being used by what

- [X] script for setting up database with postgis
- [X] terminal command for loading OSM to database - set up style file!
- script for cleaning up OSM data!
- [X] script for loading GeoDK to postgres
- [X] script for loading admin boundaries (munis)
- [X] script for indexing pop and urban data with H3 + load to postgres

- [X] update style file to include cycle-columns
- [X] script for getting road network from OSM (correct highway values, only existing network)


## Questions

- How to find components in OSM/H3?
- Will it even be necessary to build a graph?

## Analysis

- **Network density**
- **Fragmentation**  
- **Network reach**
- **Directness**

### Network density

Should be fairly easy - get H3 hexagons within XX distance

### Reach and Directness

Requires some kind of isochrones/routing - e.g. using Observable example.

### Components

Can be based on a graph object OR whether an edge can be found?



*****

https://mapscaping.com/getting-started-with-pgrouting/

java -jar osm2po-5.5.5/osm2po-core-5.5.5-signed.jar cmd=c prefix=route /Users/anev/Library/CloudStorage/Dropbox/ITU/repositories/dk_bicycle_network/data/raw/road_networks/denmark-latest.osm.pbf

<!-- java -Xmx512m -jar osm2po-core-5.5.5-signed.jar cmd=c prefix=lisbon /mnt/c/osm2pgsql_guide/Lisbon.pbf -->


psql -h localhost -p 5432 -U postgres -d postgres -q -f /Users/anev/Desktop/route/route_2po_4pgr.sql




********

SPLIT
58, 66%
8, 50%
9, 55%
10, 40%
16, 37%
5, 60%
12, 66%

TRUE
5, 60% TRUE
4, 50% TRUE
4, 50% TRUE?
5, 60% TRUE

FALSE
21, 42% FALSE
7, 29% FALSE
