# TODO

- [X] script for setting up database with postgis
- terminal command for loading OSM to database - set up style file!
- script for cleaning up OSM data!
- script for loading GeoDK to postgres
- [X] script for loading admin boundaries (munis)
- script for indexing pop and urban data with H3 + load to postgres


def import_osm(connection_string: str, path: str, path_style: str, schema: str, prefix: str = None) -> None:
    """Takes in a path to an osm pbf file and imports it to database tables."""
    prefix = f"--prefix {prefix}" if prefix else ""

    subprocess.run(f"osm2pgsql --database={connection_string} --middle-schema={schema} --output-pgsql-schema={schema} {prefix} --latlong --slim --hstore --style=\"{path_style}\" \"{path}\"", 
        shell=True, check=True)

osm2pgsql \
  --database germany_osm \
  --output flex \
  --style main.lua \
  project-data.osm.pbf

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