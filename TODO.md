# TODO

- [ ] turn 01_create_db.sql into script/make sure in can be run from python
- [ ] rename files names so it is clear what is being used by what

- [X] script for setting up database with postgis
- [X] terminal command for loading OSM to database - set up style file!
- script for cleaning up OSM data!
- [X] script for loading GeoDK to postgres
- [X] script for loading admin boundaries (munis)
- [X] script for indexing pop and urban data with H3 + load to postgres

- [X] update style file to include cycle-columns
- [X] script for getting road network from OSM (correct highway values, only existing network)

- script for FM
- script for cleaning up FM

- script for identifying intersections in OSM

- script for classifying intersections
- script for classifying cycling infrastructure
- script for indexing infra and intersections with muni

- script for indexing infra with H3

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