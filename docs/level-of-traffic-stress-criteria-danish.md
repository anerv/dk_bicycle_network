# Cyklisme og Trafik-stress: Klassificering af det danske vejnetværk

Vejnettet er inddelt i fire forskellige niveauer af 'traffik-stress'. Trafik-stress er et begreb fra den internationale cykelforskning, der beskriver hvor sikkert og komfortabelt hver strækning antages at være fra et cykelperspektiv:

* **1:** Sikkert nok for alle cyklister, inklusive børn.
* **2:** Sikkert nok for de fleste voksne cyklister.
* **3:** Kun for de erfarne og selvsikre cyklister.
* **4:** Uegnet for de fleste cyklister.

## Kriterier

Kriterierne er først og fremmest rettet mod at detektere *trafik-stress* og problemer med cykelsikkerhed. En god score betyder derfor ikke nødvendigvis at en cykelsti er perfekt for cyklister, men udelukkende at stien eller vejen bør være acceptabel for de fleste fra et trafik-stress og sikkerhedsperspektiv.

### 1. Sikkert nok for de fleste cyklister

* All *protected, dedicated bicycle infrastructure* (i.e. physically separated from motorized traffic), such as bicycle tracks separated with a curb or cycleways running separately from roads with car traffic.
* Roads with *unprotected bicycle infrastructure* (e.g. painted bicycle lane) and a max speed of 40 km/h.
* Roads with *unprotected bicycle infrastructure* and a max speed of 50 km/h if the roads has max 2 lanes of car traffic.
* Any road with a max speed of 30 km and max 2 lanes.
* Any road with a max speed of 20 km and max 3 lanes.

### 2. Sikkert nok for de fleste voksne cyklister

* Roads with *unprotected bicycle infrastsructure*, traffic speed between 40 and 50 km/h and 3-4 lanes.
* Roads with *no dedicated bicycle* infrastructure, speeds between 30 and below 50 km/h and less than 4 lanes.
* Roads with *no dedicated bicycle* infrastructure, speeds between 30 and *up to* 50 km/h and less than 4 lanes if highway/road class = *'residential'*.

### 3. Kun for de erfarne og selvsikre cyklister

* Veje med *cykelbaner*, hastighedsgrænser mellem 50 - 60 km og max. 4 vejbaner
* Veje *uden* cykelbaner/cykelstier, hastighedsgrænse på 50 km og 3 vejbaner.
* Veje *uden* cykelbaner/cykelstier, hastighedsgrænser mellem 30 og 50 km, og 4 vejbaner.
* Veje af kategorien 'unclassified' (OpenStreetMap)

* Roads with *unprotected bicycle infrastructure*, speeds between 50 and 60 km/h and max 4 lanes.
* Roads with *no dedicated bicycle infrastructure*, speeds at 50 km/h and 3 lanes.
* Roads with *no dedicated bicycle infrastructure*, speeds between 30 and 50 km/h and 4 lanes.
* Roads with road class *"unclassified"* and max 2 lanes and speed up to 80 km/h.

### 4. Uegnet for de fleste cyklister

* Veje med *cykelbane*r*, hastighedsgrænser over 50 km, og mere end 4 vejbaner
* Veje med *cykelbaner* og hastighedsgrænser på 70 km eller mere, uanset antallet af vejbaner
* Veje *uden* cykelbaner/cykelstier og hastighedsgrænser over 50 km.
* Veje *uden* cykelbaner/cykelstier og mere end 4 vejbaner.

***

Stier for fodgængere, gågade, og lignende, hvor cykling ikke er tilladt klassificeres med værdien '999', der betyder at de ikke er en del af cykelnetværket.

Stier hvor cykling er tilladt, men hvor stitype eller belægning gør stien uegnet for hverdagscyklisme klassificeres med værdien '0', og vi anbefaler ikke at inkludere dem i cykelnetværket.

***

Klassificeringen er inspireret af 'Level of Traffic Stress' (LTS)-metoden udviklet af bl.a. [Mekuria et al 2021](https://transweb.sjsu.edu/research/Low-Stress-Bicycling-and-Network-Connectivity) and [Furth et al 2016](https://journals.sagepub.com/doi/10.3141/2587-06). Mange af de kriterier der sædvanligvis anvendes i LTS gør dog brug af data, der sjældent er tilgængelige på landsplan, såsom trafiktællinger eller opgørelser over gadeparkering.

Metoden der anvendes her er derfor primært baseret på en tilpasning af LTS-kriterierne til OpenStreetMap data, udviklet af [Wasserman et al 2019](https://journals.sagepub.com/doi/full/10.1177/0361198119836772), men simlificeret og tilpasset til den danske kontekst.
