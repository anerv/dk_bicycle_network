# Cyklisme og Trafik-stress: Klassificering af det danske vejnetværk

Vejnettet er inddelt i fire forskellige niveauer af 'trafik-stress'. Trafik-stress er et begreb fra den internationale cykelforskning, der beskriver hvor sikkert og komfortabelt hver strækning antages at være fra et cykelperspektiv:

* **1:** Sikkert nok for alle cyklister.
* **2:** Sikkert nok for de fleste voksne cyklister.
* **3:** Kun for de erfarne og selvsikre cyklister.
* **4:** Uegnet for de fleste cyklister.

## Kriterier

Kriterierne er først og fremmest rettet mod at detektere *trafik-stress* og problemer med cykelsikkerhed. En god score betyder derfor ikke nødvendigvis at en cykelsti er perfekt for cyklister, men udelukkende at stien eller vejen bør være acceptabel for de fleste fra et trafik-stress og sikkerhedsperspektiv.

### 1. Sikkert nok for de fleste cyklister

* Al beskyttet, dedikeret cykelinfrastruktur - dvs. cykelstier og andre stier, der fysisk er separeret fra motoriseret trafik.
* Veje med *cykelbaner* og hastighedsgrænser på maks. 40 km/t.
* Veje med *cykelbaner*, hastighedsgrænser på maks. 50 km, og maks. 2 vejbaner.
* Veje med hastighedsgrænser på maks. 30 km/t og maks. 2 vejbaner (undtagen veje med bustraffik - se LTS 2).
* Veje med hastighedsgrænser på maks. 20 km/t og maks. 3 vejbaner (undtagen veje med bustraffik - se LTS 2).

### 2. Sikkert nok for de fleste voksne cyklister

* Veje med *cykelbaner*, hastighedsgrænser mellem 40 og 50 km/t og 3-4 vejbaner.
* Veje *uden* cykelbaner/cykelstier, hastighedsgrænser mellem 30 og *mindre end* 50 km/t og maks. 3 vejbaner.
* Beboelsesveje *uden* cykelbaner/cykelstier, maks. 3 vejbaner og hastighedsgrænser mellem 30 og *op til* 50 km/t. (Beboelsesveje har vejklasses highway='residential' i OpenStreetMap).
* Veje *uden* cykelbaner/cykelstier, hastigheder op til 30 km/t og som indgår i en busrute.
* Veje med *cykelbaner*, hastigheder under 50 km/t og som indgår i en busrute.

### 3. Kun for de erfarne og selvsikre cyklister

* Veje med *cykelbaner*, hastighedsgrænser mellem 50 - 60 km/t og maks. 4 vejbaner.
* Veje *uden* cykelbaner/cykelstier, hastighedsgrænse på 50 km/t og 3 vejbaner.
* Veje *uden* cykelbaner/cykelstier, hastighedsgrænser mellem 30 og 50 km/t, og 4 vejbaner.
* Veje af kategorien 'uklassificeret' (OpenStreetMap highway=unclassified), maks. 2 vejbaner, og hastighedsgrænser op til 80 km/t. Veje i denne vejklasse er typisk mindre veje, der kun benyttes af lokal trafik, og som i praksis sjældent tillader høje hastigheder.
* Større veje (af kategorien 'primær', 'sekundær' eller 'tertiær') *uden* cykelbane/cykelstier og hastigheder over 50 km/t.
* Veje *uden* cykelbaner/cykelstier, hastighedsgrænser mellem 30+ og 50 km/t, og som indgår i en busrute.
* Veje med *cykelbaner*, hastighedsgrænser mellem 50+ - 60 km/t, og som indgår i en busrute.

### 4. Uegnet for de fleste cyklister

* Veje med *cykelbaner*, hastighedsgrænser over 50 km/t, og mere end 4 vejbaner
* Veje med *cykelbaner* og hastighedsgrænser på 70 km/t eller mere, uanset antallet af vejbaner
* Veje *uden* cykelbaner/cykelstier og hastighedsgrænser over 50 km/t.
* Veje *uden* cykelbaner/cykelstier og mere end 4 vejbaner.

***

### Øvrige vejnet

De resterende dele af vejnettet kan inddeles i tre kategorier:

* Veje, hvor cykling ikke er tilladt. Det kan både dreje sig om eksempelvis motorveje, men også om veje med en separat cykelsti, hvor cyklister derfor skal benytte sig af cykelstien.

* Stier for fodgængere, gågader, og lignende, hvor cykling ikke er tilladt.

* Stier hvor cykling er tilladt, men hvor stitype eller belægning gør stien uegnet for hverdagscyklisme.

## Input data

Klassificeringen er baseret på informationer tilgængelig i OpenStreetMap, data på cykelstier og cykelbaner i GeoDanmark, samt en række antagelser om primært hastighedsgrænser og antal vejbaner, i tilfælde hvor data ikke er tilgængelig.

Klassificeringen medtager pt. ikke informationer om cykelsikkerhed og komfort ved kryds.

## Baggrund

Klassificeringen er inspireret af 'Level of Traffic Stress' (LTS)-metoden udviklet af bl.a. [Mekuria et al (2012)](https://transweb.sjsu.edu/research/Low-Stress-Bicycling-and-Network-Connectivity) and [Furth et al (2016)](https://journals.sagepub.com/doi/10.3141/2587-06). Mange af de kriterier der sædvanligvis anvendes i LTS gør dog brug af data, der sjældent er tilgængelige på landsplan, såsom trafiktællinger eller opgørelser over gadeparkering.

Metoden der anvendes her, er derfor primært baseret på en tilpasning af LTS-kriterierne til OpenStreetMap data, udviklet af [Wasserman et al (2019)](https://journals.sagepub.com/doi/full/10.1177/0361198119836772), men simplificeret og tilpasset til den danske kontekst.
