# Installation

The code is based on a combination of Python and SQL scripts.

<!-- INSERT LOGOS -->
To run the code, first install the required dependencies:

## **1. Clone the GitHub repository**

First [clone](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) this repository (recommended) to your local machine or download it.

To avoid cloning the history and larger branches with example data and plots, use:

```
git clone -b main --single-branch [url to GitHub repository] --depth 1
```

## **2. Install Postgresql**

Install Postgresql version 14.10 or newer.

See [this link](https://dev.to/letsbsocial1/installing-pgadmin-only-after-installing-postgresql-with-homebrew-part-2-4k44) for a guide to installing Postgresql with homebrew on Mac.

PgAdmin is not required, but can be useful when inspecting the results: [Guide for installing PgAdmin](https://www.heatware.net/postgresql/installing-pgadmin-4-on-mac-os-with-brew-a-comprehensive-guide/).

## **3. Install PostGIS and PgRouting**

Install the Postgresql extensions [PostGIS](https://postgis.net/) and [PgRouting](https://pgrouting.org/).

If using homebrew, once Postgresql is installed, run:

`brew install postgis`

`brew install pqrouting`

## **4. Install osm2pgsql**

[osm2pgsql](https://osm2pgsql.org/doc/install.html) is used to load OSM to Postgresql with all desired OSM tags.

On Mac, osm2pgsql can be installed by running:

`brew install osm2pgsql`

## **5. Install osm2po**

[osm2po](https://osm2po.de/) is used for loading OSM data to Postgresql in a format compatible with PgRouting.

The necessary files are *already included* in this repository. If a newer version is needed, replace the content in the folder osm2po. (See e.g. [this link](https://mapscaping.com/getting-started-with-pgrouting/) for an installation guide.)

*If* a newer version is used, once installed, replace the osm2po.config file with the one included on this repository.

## **6. Install GDAL**

Used for loading the GeoDanmark geopackage to PostgreSQL.

On mac, run:

`brew install gdal`

## **7. Create conda environment**

To ensure that all packages needed for the analysis are installed, it is recommended to create and activate a new conda environment using the `environment.yml`:

```
conda env create --file=environment.yml
conda activate dk_bike_network
```

If this fails, the environment can be created by running:

```
conda config --prepend channels conda-forge
conda create -n dk_bike_network --strict-channel-priority geopandas psycopg2 sqlalchemy geoalchemy2 pyarrow rasterio rioxarray h3-py qgis ipykernel
```

## **8. Install src package**

The repository has been set up using the structure described in the [Good Research Developer](https://goodresearch.dev/setup.html). Once the repository has been downloaded, activate the dk_bike_network environment, navigate to the main folder in a terminal window and run the commands:

```
conda activate dk_bike_network
conda install pip
pip install -e .
```

## **9. Download data**

The workflow makes use of 5 different data sets:

1. **OpenStreetMap**
Download the newest OSM-pbf file for Denmark (`denmark-latest.osm.pbf`) from, for example, [GeoFabrik](https://download.geofabrik.de/europe/denmark.html) and place it in the folder `data/raw/road_networks/`.

2. **GeoDanmark**
Download the data set of the Danish road network ('Vejmidte') from [Dataforsyningen](https://dataforsyningen.dk/data/1049) and place it as `vejmidte.gpkg` in `data/raw/road_networks/`.

3. **Municipal boundaries**
Download the data set with municipal boundaries from [Dataforsyningen](https://dataforsyningen.dk/data/3901) and place it in the folder `data/raw/study_area/muni_boundary.gpkg`.

4. **Land use**
Download the data set of urban and summerhouse zones from e.g. [Miljøportalen](https://arealdata.miljoeportal.dk/datasets/urn:dmp:ds:planlaegning-zonekort) and place it in the folder `data/raw/urban/` with the file name `zonekort_samlet_v.gpkg`.

5. **Population data**
Download the two population rasters covering Denmark including Bornholm at [GHSL](https://ghsl.jrc.ec.europa.eu/download.php?ds=pop) and place them in the folder `data/raw/pop`. Update the file paths to the population rasters in `config.yml` if necessary.
