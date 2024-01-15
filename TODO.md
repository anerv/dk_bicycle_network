# TODO

- [X] New script for loading OSM to DB with osm2po
- [X] Transfer tags to edges
- [X] Adapt matching to use network edges
- [X] Mark all edges as matched/unmatched
- [X] Add additional cycling info
- [X] interpolate missing tags
- [X] script for identifying intersections in OSM
- [X] script for classifying intersections
- [X] script for indexing infra with muni
- [X] split matching so geodk bike lanes are only matched to non-bike??

- [ ] LTS CLASSIFICATION
- [X] Close cycling gaps

- [ ] clean up script: drop osm_roads, planet tables
- [ ] export script: drop unneccessary columns (keep pgrouting, cycling, surface, speed, matching, assumed_tags, lts - or remove matching or org tags?)

- [ ] documentation
- [ ] add caveat about matching to documentation - edges with more than 3 parts of matched/unmatched

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
