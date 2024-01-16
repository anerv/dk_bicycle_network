# Data Preprocessing for 'A Network Analysis of the Danish Bicycle Infrastructure'

This repository contains the code for creating a routable road network for all of Denmark with each road assigned a Low Traffic Stress score based on the cycling friendliness ([Mekuria et al 2021](https://transweb.sjsu.edu/research/Low-Stress-Bicycling-and-Network-Connectivity) and [Wasserman et al 2019](https://journals.sagepub.com/doi/full/10.1177/0361198119836772)).

The road network is based on data from OpenStreetMap but enriched with bicycle infrastructure data from [GeoDanmark](https://www.geodanmark.dk) to improve data completeness on dedicated bicycle infrastructure.

For further instructions, see the installation instructions (*docs/installation.md*) and the guide (*docs/how-to.md*).

## Data & Licenses

**The code is free to use and repurpose under the [AGPL 3.0 license](https://www.gnu.org/licenses/agpl-3.0.html).**

The repository includes data from the following sources:

### OpenStreetMap

© OpenStreetMap contributors  
License: [Open Data Commons Open Database License](https://opendatacommons.org/licenses/odbl/)

Downloaded fall 2023 from GeoFabrik.

### GeoDanmark

Data from GeoDanmark © SDFE (Styrelsen for Dataforsyning og Effektivisering og Danske kommuner)  
License: [GeoDanmark](https://www.geodanmark.dk/wp-content/uploads/2022/08/Vilkaar-for-brug-af-frie-geografiske-data_GeoDanmark-grunddata-august-2022.pdf).

Downloaded fall 2023.

### Bolig- og Planstyrelsen

[Areal data for urban zones](https://arealdata.miljoeportal.dk/datasets/urn:dmp:ds:planlaegning-zonekort).

License: [Arealdata](https://arealdata.miljoeportal.dk/terms).

Downloaded winter 2024.

<!-- ### GHSL

Contains data from the European Commission's GHSL (Global Human Settlement Layer) on [population](https://ghsl.jrc.ec.europa.eu/download.php?ds=pop) and [degree of urbanization](https://ghsl.jrc.ec.europa.eu/ghs_smod2023.php).

Schiavina M., Freire S., Carioli A., MacManus K. (2023):
GHS-POP R2023A - GHS population grid multitemporal (1975-2030). European Commission, Joint Research Centre (JRC). -->

<!-- Schiavina M., Melchiorri M., Pesaresi M. (2023):
GHS-SMOD R2023A - GHS settlement layers, application of the Degree of Urbanisation methodology (stage I) to GHS-POP R2023A and GHS-BUILT-S R2023A, multitemporal (1975-2030). European Commission, Joint Research Centre (JRC) -->

Downloaded fall 2023.

## Credits

Supported by the Danish Road Directorate.
