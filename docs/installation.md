# Installation

The code is based on a combination of Python and SQL scripts.
To run the code, first install the required dependencies:

1. **Clone the GitHub repository:**

2. **Install Postgresql:**

See e.g. https://dev.to/letsbsocial1/installing-pgadmin-only-after-installing-postgresql-with-homebrew-part-2-4k44 and https://www.heatware.net/postgresql/installing-pgadmin-4-on-mac-os-with-brew-a-comprehensive-guide/ for guides for installing Postgresql with homebrew.

PgAdmin is not required, but can be useful when inspecting the results.

3. **Install PostGIS and PgRouting**

If using homebrew, once Postgresql is installed, run:

`brew install postgis`

`brew install pqrouting`

4. **Install osm2po**

See e.g. https://mapscaping.com/getting-started-with-pgrouting/

Replace the osm2po.config file with the one included on this repository.

5. **Create conda environment**

install pip src
