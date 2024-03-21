# Data preprocessing for 'A Network Analysis of the Danish Bicycle Infrastructure'

This repository contains the code for creating a routable road network for all of Denmark with each road assigned a Level of Traffic Stress score based on the cycling friendliness ([Mekuria et al 2021](https://transweb.sjsu.edu/research/Low-Stress-Bicycling-and-Network-Connectivity) and [Wasserman et al 2019](https://journals.sagepub.com/doi/full/10.1177/0361198119836772)). The classification is based on previous research in this area, but adapted to a Danish context.

The road network is based on data from OpenStreetMap enriched with bicycle infrastructure data from [GeoDanmark](https://www.geodanmark.dk) to improve data completeness on dedicated bicycle infrastructure.

For further instructions, see the [*docs/installation.md*](docs/installation.md) and the [*docs/how-to.md*](docs/how-to.md).

To read more on how the LTS scores have been computed, see [*docs/low-traffic-stress-criteria.md*](docs/level-of-traffic-stress-criteria.md).

## Data & Licenses

**The code is free to use and repurpose under the [AGPL 3.0 license](https://www.gnu.org/licenses/agpl-3.0.html).**

The repository includes data from the following sources:

### OpenStreetMap

© OpenStreetMap contributors  
License: [Open Data Commons Open Database License](https://opendatacommons.org/licenses/odbl/)

Downloaded winter 2024 from GeoFabrik.

### GeoDanmark

Data from GeoDanmark © SDFI (Styrelsen for Dataforsyning og Infrastruktur og Danske kommuner)  
License: [GeoDanmark](https://www.geodanmark.dk/wp-content/uploads/2022/08/Vilkaar-for-brug-af-frie-geografiske-data_GeoDanmark-grunddata-august-2022.pdf).

Downloaded fall 2023.

### Bolig- og Planstyrelsen

[Areal data for urban zones](https://arealdata.miljoeportal.dk/datasets/urn:dmp:ds:planlaegning-zonekort).

License: [Arealdata](https://arealdata.miljoeportal.dk/terms).

Downloaded winter 2024.

### SDFI

[Urban areas](https://dataforsyningen.dk/data/1038)

License: [SDFI](https://dataforsyningen.dk/asset/PDF/rettigheder_vilkaar/Vilk%C3%A5r%20for%20brug%20af%20frie%20geografiske%20data.pdf)

Downloaded winter 2024.

<!-- ### GHSL

Contains data from the European Commission's GHSL (Global Human Settlement Layer) on [population](https://ghsl.jrc.ec.europa.eu/download.php?ds=pop) and [degree of urbanization](https://ghsl.jrc.ec.europa.eu/ghs_smod2023.php).

Schiavina M., Freire S., Carioli A., MacManus K. (2023):
GHS-POP R2023A - GHS population grid multitemporal (1975-2030). European Commission, Joint Research Centre (JRC). -->

<!-- Schiavina M., Melchiorri M., Pesaresi M. (2023):
GHS-SMOD R2023A - GHS settlement layers, application of the Degree of Urbanisation methodology (stage I) to GHS-POP R2023A and GHS-BUILT-S R2023A, multitemporal (1975-2030). European Commission, Joint Research Centre (JRC) -->

<!-- Downloaded fall 2023. -->

## Credits

Supported by the Danish Road Directorate.
