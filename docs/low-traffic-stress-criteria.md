# Low Traffic Stress Classification of the Danish Road Network

The oad network is classified into four different levels of 'traffic stress' (LTS), as conceptualized by e.g. [Mekuria et al 2021](https://transweb.sjsu.edu/research/Low-Stress-Bicycling-and-Network-Connectivity) and [Furth et al 2016](https://journals.sagepub.com/doi/10.3141/2587-06). Many of the criteria being used in the original LTS classifications make use of data that often are not available such as traffic counts, width of bicycle infrastructure, or the presence of on-street parking.

The LTS simplification used here is inspired by the adaptiation of LTS criteria for OpenStreetMap data by [Wasserman et al 2019](https://journals.sagepub.com/doi/full/10.1177/0361198119836772), but simplified and adapted to the Danish context.

All roads with car traffic and all cycleways, lanes and paths that are classified as 'bicycle infrastructure' is given a LTS value from 1-4, corresponding to the traditional use of the LTS classes:

* **LTS 1:** Safe enough for all cyclists.
* **LTS 2:** Tolerated by most adults.
* **LTS 3:** For the confident cyclists.
* **LTS 4:** For the "strong and fearless" [Geller, 2006, Dill and McNeil, 2016](https://journals.sagepub.com/doi/10.3141/2587-11)

Notice that roads are also given a LTS value even if they have no public access.

Footways, paths, pedestrian areas etc. that do not allow for cycling are given a LTS value of 999, indicating that thet are not part of the cycling network. Footways, paths, pedestrian areas etc. where cycling is allowed but the surface is deemed insufficient for cycling are given a LTS value of 0 and we recommend excluding them from the bicycle network.

## LTS Critera

The LTS criteria are aimed at detecting *traffic stress* and issues with traffic safety. A good LTS score does thus not mean that e.g. a bicycle track is perfect for cyclists, but that is, from a safety and traffic stress perspective, should be tolerable for most people.

### LTS 1

* All *protected, dedicated bicycle infrastructure* (i.e. physically separated from motorized traffic), such as bicycle tracks separated with a curb or cycleways running separately from roads with car traffic.
* Roads with *unprotected bicycle infrastructure* (e.g. painted bicycle lane) and a max speed of 40 km/h.
* Roads with *unprotected bicycle infrastructure* and a max speed of 50 km/h if the roads has max 2 lanes of car traffic.
* Any road with a max speed of 30 km and max 2 lanes.
* Any road with a max speed of 20 km and max 3 lanes.

### LTS 2

* Roads with *unprotected bicycle infrastsructure*, traffic speed between 40 and 50 km/h and 3-4 lanes.
* Roads with *no dedicated bicycle* infrastructure, speeds between 30 and below 50 km/h and less than 4 lanes.
* Roads with *no dedicated bicycle* infrastructure, speeds between 30 and *up to* 50 km/h and less than 4 lanes if highway/road class = *'residential'*.

### LTS 3

* Roads with *unprotected bicycle infrastructure*, speeds between 50 and 60 km/h and max 4 lanes.
* Roads with *no dedicated bicycle infrastructure*, speeds at 50 km/h and 3 lanes.
* Roads with *no dedicated bicycle infrastructure*, speeds between 30 and 50 km/h and 4 lanes.
* Roads with road class *"unclassified"* and max 2 lanes and speed up to 80 km/h.

### LTS 4

* Roads with *unprotected bicycle infrastructure*, traffic speed above 50 km/h and 5 lanes or more
* Roads with *unprotected bicycle infrastructure* and traffic speeds above 70 km/h regardless of the number of lanes of car traffic.
* Any road without dedicated bicycle infrastructure and speeds above 50 km/h
* Any road without dedicated bicycle infrastructure and more than 4 lanes.

***

### LTS 0

* All stretches where cycling is allowed but the surface is deemed unsuitable for regular cyclists.

### LTS 999

* All stretches where cycling is not allowed and there are no car traffic (typically pedestrian paths).