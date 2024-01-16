# How to use

## Installation

See `installation.md` for instructions for installation of necessary software and where to download the input data.

## Code description

The data processing workflow for producing the enriched OSM road network for bicycle LTS analysis consist of a number of Python and PostgreSQL scripts.
All SQL scripts are run through Python. The SQL scripts are labelled with a number referencing the Python script in which they are used (for example, `00_create_db.py` makes use of `00_create_db.sql` and `03_match_osm_geodk.py` makes use of all SQL scripts starting with `03x_xxx.sql`).

The Python scripts must be run in numerical order. They can either be run one-by-one (in this way, intermediate results can be examined) or alternatively, navigate to the scripts folder in this repository, activate the conda environment `dk_bike_network` and run:

``` python
python scripts/run_all_scripts.py
```

## Conflation of OSM and GeoDanmark data

An important part of the workflow is the conflation of OSM and GeoDanmark data on bicycle tracks and lanes.
For further details see `network_matching.md`.

## LTS classification

See `low_traffic_stress_critera.md` for further details on the LTS classification.

## Final datasets

The final outcome of the data procesing is 2 data sets: A table with OSM road network edges enriched with GeoDanmark data and classified with an LTS value and additional cycling characteristics, and a corresponding node data set.
One the workflow is completed both data sets are exported to the `data/processed/` folder.

For an overview of the included columns in the data, that are not originally part of the OSM data set, see `bicycle_classification.md`. See the documentation for PgRouting for explanations of remaining columns.
