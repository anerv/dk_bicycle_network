# Conflation of OSM and GeoDanmark data

An important part of the workflow is the conflation, or *feature matching*, of OSM and GeoDanmark data on bicycle tracks and lanes.
The conflation is based on a feature matching procedure of OSM and GeoDanmark segments as done by e.g. [Koukoletsos et al. (2012)](http://www.geog.leeds.ac.uk/groups/geocomp/2011/papers/koukoletsos.pdf) and [Will (2014)](https://www.semanticscholar.org/paper/Development-of-an-automated-matching-algorithm-to-%3A-Will/b3b77d579077b967820630db56522bef31654f21).

The feature matching is done in 13 steps:

1. **Prepare data (03a)**

* Create schemas.
* Extract data for matching.
* Merge geometries where possible.

2. **Create segments (03b)**

* Divide both data sets into segments of equal length

3. **Process segments (03c)**

* Divide segments into different tables based on the presence and type of bicycle infrastructure..

4. **Find candidates bike (03d)**

* Find potential candidates between GeoDanmark data and OSM data with bicycle infrastructure

5. **Find best match bike (03e)**

* Find best matches for all segments from potential matches from step 4.

6. **Find unmatched GeoDK segments (03f)**

* Find GeoDK segments that were not matched to OSM bike segments.

7. **Find candidates no bike (03g)**

* Find candidates between unmatched GeoDK segments and OSM segments with no bicycle infrastructure.

8. **Find best matches no bike (03h)**

* Find best matches from candidates from step 7.

9. **Process matches (03i)**

* Identify matched *edges* based on the share of matched segments.

(Part of this step happens in the Python script 03).

10. **Identify matches edges (03j)**

* Identify matched OSM edges (going from segment to edge level).

NOTE: Edges that are only partly matched, and where the matched segments are not adjacent are not marked as matched. A manual inspection is recommended.

11. **Rebuild topology (03k)**

* Rebuild graph topology after splitting edges in step X.

12. **Close matching gaps (03l)**

* Identify and close gaps in matched edges.

13. **Transfer GeoDK attributes (03m)**

* Transfer GeoDK attributes to corresponding OSM edges.
