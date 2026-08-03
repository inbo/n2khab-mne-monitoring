---
aliases:
tags:
  - mnmsurfdb
  - Visits
  - Observations
started:
finished:
execution:
status: false
---

related / finishing up:
+ [[carve out field forms draft for mnmsyncdb]]
+ [[draft and implement a database for fieldwork support of surface water monitoring]]

using:
+ [[sql_tricks/update rule with conditional insert|update rule with conditional insert]]


## TODO

+ [x] #Visits 
	+ fields +3
+ [x] #LenticVisits 
	+ fields +3 (-6)
	+ all comments
+ [x] #Observations 
	+ fields +3
	+ all comments
+ [x] ++ #SampleContextObservations
+ [x] #PerturbationObservations
	+ fields +14
	+ all comments
+ [x] #MeteorolObservations
	+ fields +1 (-1)
	+ all comments
+ [x] extra expost triggers (sync mod)
+ [x] view
	+ old one - rename columns
	+ new - including linked Observations
	+ update and insert rules
+ [x] Observations update visit_id by grts_address in `102_re_link_foreign_keys.R`

+ [ ] *ex post*: for observation not coupled to datacoll: link grts to `location`!
	+ expost rule which tries to extract `grts_address::int` from `location::varchar`
	+ also link and shift "historic" data
	+ consider filtering plain observations for the unlinked ones (no: specific selection is useful)

+ [ ] update forms for just Observations when they are independent of DATACOLL
+ [ ] adjust labels and identifiers of all #Observations tables
+ [ ] copy to Planning project
+ [ ] document technical choices of #Visits -- #Observations optional coupling



LATER:
+ [ ] update data from obsolete columns
	+ [ ] sample_contamination?
	+ [ ] `chlorophytae_presence`/`chlorophytae_specification` infer from outdated `open_water`, `phytoplankton`, and `float_layer`
	+ [ ] *others?*
+ [ ] also update #LoticVisits
+ [ ] remove tables after migrating and saving data
	+ [ ] GeoObservations
	+ [ ] TerraBioObservations
	+ [ ] AquaBioObservations
	+ [ ] LanduseObservations
+ [ ] remove excess columns in tables above



## input
### initial
Ondertussen hebben we een paar weken veldwerk achter de rug en weten we al
beter welke veldwaarnemingen we willen noteren en welke minder belangrijk
zijn. We zouden daarom graag de velden in de QField-app verder
optimaliseren. Zou het mogelijk zijn om de volgende wijzigingen door te
voeren, a.u.b.? Dergelijke indeling lijkt voor de veldmedewerkers handig en
efficiënt om de data te noteren. Dit mag gerust ook na je verlof.

*(1) Zouden er bij  "staalname effectief" volgende velden in onderstaande
volgorde kunnen worden toegevoegd:*
- [x] teamlid observerend
- [x] datum bezoek
- [x] uur bezoek
- [x] GRTS
- [x] Diepte op staalnamepunt (cm)
- [x] Secchi-diepte op staalnamepunt (cm)
- [x] Slibdikte op staalnamepunt (cm)

- [x] Volledige afwezigheid van vegetatie, metaphyton en/of drijflaag (TRUE/FALSE). Standaard op TRUE zetten. Indien FALSE, extra veld laten
verschijnen:
	- [x] "specificeer afwijking open water en effect op staal"
	- *cf.* http://palaeos.com/eukarya/plantae/plantae.html

- [ ] Extra opmerkingen
- [ ] Foto observatie (optioneel)

*(2) Zouden bij "bijkomende observaties" de categorieën veranderd kunnen
worden naar onderstaande? Deze worden in deze volgorde in het veld
overlopen, handig dat dit zo in app* *zou staan*.
- Staal
- De plas
- Verstoringen
- Meteo

*(3)** Bij "Staal" mogen volgende velden genoteerd worden (gelieve ook de
opties tussen haakjes weer te geven)*:
- [x] zuiver staal (TRUE/FALSE). Zet standaard op TRUE. Indien FALSE, laat een 
	- [x] veld verschijnen met "specificeer reden onzuiverheid".
- [x] monstername apparatuur (wadend, schepstok)
- [x] kleur (geen, geel, oranje, bruin, zwart, groen, grijs, rood)
- [x] geur (geen, metallisch, zwavel, ammoniak, mest, riool, visachtig)
- [x] zoöplankton (geen, weinig, matig, veel)
- [x] macroinvertebraten (geen, weinig, matig, veel)
- [x] LIMS projectcode
- [x] LIMS staalcode
- [x] pH
- [x] T (°C)
- [x] EC (µS/cm)
- [x] DO (mg/L)
- [x] DO%
- [x] Sneller
- [ ] Extra opmerkingen
- [ ] Foto observatie (optioneel)

*(4) Bij "De plas" mogen volgende velden genoteerd worden, graag in
onderstaande volgorde (tekstuele aanpassingen t.o.v. huidige versie staan
in het vet, wil je deze ook toevoegen, aub?). Dit is een samenvoeging van
elementen uit de huidige lagen "geografie en morfologie", "aquatische
biologie" en "terrestrische biologie en omgeving".*
- [x] Bladinval *(%)*
- [x] Beschaduwing *(%)*
- [x] Emergente *vegetatie* (bedekking %)
- [x] Pleustofyten (bedekking %)
- [x] Nymphaeiden (bedekking %)
- [x] *Submerse vegetatie (bedekking %)*
- [x] *Submerse vegetatie (PVI) *--> dit in plaats van verticale projectie infestatie
- [x] Metaphyton (bedekking %)
- [x] Open water (bedekking %) --> dit in plaats van bedekkingsgraad
- [x] *Maximale diepte (cm) *
- [x] *Kwelinvloed (niet, iriserende film, roestbruinig water of slib) *--> nieuw element
- [x] Connectiviteit *(gesloten, instroom, doorstroom, overstroomd)*
- [x] *Grof organisch materiaal (weinig, matig, veel) *--> dit in plaats van "waterbodem".
- [ ] *Foto plas t.h.v. staalnamepunt (verplicht)*
- [ ] *Extra* opmerkingen
- [ ] *Foto observatie (optioneel)*

De rest in de huidige versie mogen in principe weggelaten worden, i.e. alle
elementen m.b.t. oever, specificatie watervegetatie, specificatie
drijvende, interpretatie waterplanten. Zoöplankton en macroinvertebraten
zijn verplaatst naar "Staal". Invasieve exoten en aanwezigheid van grote
aquatische dieren zouden we willen onderbrengen onder "verstoringen".

(5) *Bij "Verstoring" mogen volgende velden genoteerd worden, graag in
onderstaande volgorde (tekstuele aanpassingen t.o.v. huidige versie staan
in het vet, wil je deze ook toevoegen, aub?). Dit is een samenvoeging van
elementen uit de huidige lagen "aquatische biologie", "terrestrische
biologie en omgeving", "verstoringen" en "landgebruik". *

- [x] *Koeienvlaaien* (TRUE/FALSE)
- [x] *Andere dierlijke mest* (TRUE/FALSE) --> "dierlijke mest" in huidige versie opdelen in twee elementen (zijnde "koeienvlaaien" en "andere dierlijke mest")
- [x] Grazers (TRUE/FALSE)
- [x] *Trampling* (TRUE/FALSE)
- [x] (Intensieve) veehouderij *in de buurt* (TRUE/FALSE)
- [x] *Akkers in de buurt* (TRUE/FALSE)
- [x] Recente bemesting *in de buurt* (TRUE/FALSE)
- [x] Drukke verkeerswegen* in de buurt *(TRUE/FALSE)
- [x] *Industrie in de buurt *(TRUE/FALSE)
- [x] Vis (TRUE/FALSE)
- [x] *Vogels* (TRUE/FALSE)
- [x] *Vogeluitwerpselen* (TRUE/FALSE)
- [x] Bever (TRUE/FALSE)
- [x] *Invasieve soorten* (TRUE/FALSE)

- [x] Oeverversteviging (TRUE/FALSE)
- [x] Drainagestructuren (buizen, grachten) (TRUE/FALSE)
- [x] Prikkel- of schrikdraad (TRUE/FALSE)
- [ ] *Extra* *opmerkingen (vb. intensiteit van verstoring, ID van soorten, andere verstoringen)*
- [ ] *Foto observatie (optioneel)*

De velden "landgebruik observatie" en "sectoriële milieudrukken" in de
huidige laag "landgebruik" mag je weglaten.

*(6) Bij "meteo" mogen volgende velden genoteerd worden, graag in
onderstaande volgorde (tekstuele aanpassingen t.o.v. huidige versie staan
in het vet, wil je deze ook toevoegen, aub?)*

- [x] *neerslag op moment van staalname* (true/false).
	- [x] Indien TRUE, laat opties zien "*soort neerslag (regen, hagel, sneeuw)*" 
	- [x] en "*intensiteit (licht, matig, zwaar)*"
- [x] Indien FALSE, laat optie zien "*actuele bewolking (zonnig, licht, zwaar, betrokken, mistig)*"
- [x] luchttemperatuur (°C)
- [x] *actuele windcondities (geen, zwak, matig, sterk)*
- [x] *weer afgelopen 48 uur *
- [x] *extra opmerkingen (vb. extreme weersomstandigheden)*
- [x] *foto observatie (optioneel)*
- [x] ? ijslaag

Het huidige veld "actueel weer" mag eigenlijk weggelaten worden.

*(7) Bij elke laag stonden tevens volgende elementen:*

teamlid observerend
datum bezoek
locatie

### review round 1


- (0) Tab "activiteit" 
	- [x] "foto locatie t.h.v. staalnamepunt", ipv foto locatie.
- (1) Tab "staalname en staalnamepunt"
	- [x] Sliblaag i.p.v. sliplaag. 
	- [x] Secchi bodemzicht i.p.v. secchi op grond
	- [x] "Specificatie phytae" vervangen door "specificatie afwijking open water en effect op staal" 
	- [x] veld "opmerkingen" en "foto" aan toevoegen -> ==too many photos!== -> *added note and add photo to "staalname effectief"*
- (2) Tab "staalchemie"
	- [x] datum calibratie sondes mag weg. 
	- [ ] kan hier ook "foto" aan worden toegevoegd? ==too many photos==
- (3) Tab "staal uiterlijk".
	- [x] opties nog toevoegen voor kleur, geur, ZP en MI. ==fiddicult==
	- [x] Kan hier ook "foto" aan worden toegevoegd?
- (4) Tab "bijkomend" 
	- [x] de titel veranderen naar "**omgevingsdata**"
- (5) Tab "poel en context" --> "poel" 
	- [x] Opmerkingen onderaan i.p.v. bovenaan (cf. andere tabs)
	- wat bedoel je met "aandacht!"? ==alert - opvolgen==
	- [x] "foto staalnamepunt" vervangen door "foto omgeving" en ook onderaan plaatsen. De foto ter hoogte van staalnamepunt onder tab "activiteit". 
	- [ ] ==datatype== max. diepte: kan dit open veld zijn, We noteren vaak > of < een bepaalde waarde (of klasse 1, klasse 2, ...) ==issue: review false entries==
	- [x] opties nog meegeven voor connectiviteit (gesloten, instroom, doorstroom, overstroomd), 
	- [x] opties kwelinvloed (niet, iriserende film, roestbruinig water of slib), 
	- [x] opties grof organisch materiaal (weinig, matig, veel)
	- [ ] ==datatype== kunnen alle % velden (van de vegetatie) open velden zijn? We noteren hier voornamelijk klassen. ==welke concreet?==
	- [x] veld "niet-open wateroppervlak (%)" mag weg, is gecapteerd onder de andere. Graag bij de velden over vegetatie nog een veld "open water (%)". ==renamed: "bedekkingsgraad"==
- (6) Tab "verstoringen"
	- [x] Opmerkingen, foto onderaan i.p.v. bovenaan. Zelfde vraag over "aandacht!" als hierboven.
	- [x] drainagestructuren, prikkel- of schrikdraad mogen gerust ook aan/afvinkhokjes zijn.
- (7) Tab "meteo"
	- [x] Opmerkingen, foto onderaan i.p.v. bovenaan. Zelfde vraag over "aandacht!" als hierboven.
	- [x] indien mogelijk, nog een "specificatie"-veld laten verschijnen bij aanklikken "uitzonderlijke weersomstandigheden" ==datatype changed==

- (8) Lagen "bijkomende observaties"
	- [x] Ik zou de titel van de laag veranderingen naar "geografische aanduiding omgevingsdata" zodat men weet dat men hiermee locaties in de plas kan aanduiden waarop een bepaalde observatie onder "omgevingsdata" slaat (zie opmerking 4 in deze mail).
	- [x] in principe staan hier opties nog in die ondertussen onder "mijn veldwerk" staan. Als dat nog lukt, mogen die weg. Wel zeker een veld opmerking laten zodat duidelijk is waar men precies naar verwijst.
	- [x] ik zou de namen consistent houden aan de tabs in "mijn veldwerk": "Staal en context" --> "poel", "weer en onweer" --> "meteorologie"


TODO:
- [x] comment Visits.photo
- [x] ++ SamplingPoints.photo
- [x] ++ LenticVisits.xphoto_sample
- [x] data type changes
	- [x] DT! PerturbationObservations.drainage_structures TO boolean
	- [x] DT! PerturbationObservations.fencing TO boolean
	- [x] DT! MeteorolObservations.exceptional TO varchar
	- others: question
- [x] QField test: comments as GroupBox? (e.g. connectivity)

- [ ] rm LenticVisits.latest_calibration

```sql
COMMENT ON COLUMN "inbound"."Visits".photo IS E'mandatory photo of the sampling site at target location';

ALTER TABLE "inbound"."SamplingPoints" ADD COLUMN photo varchar; 
COMMENT ON COLUMN "inbound"."SamplingPoints".photo IS E'optional photo of the sampling location to illustrate irregularities';

ALTER TABLE "inbound"."LenticVisits" ADD COLUMN xphoto_sample varchar; 
COMMENT ON COLUMN "inbound"."LenticVisits".xphoto_sample IS E'extra photo of the sample water in a bucket';

ALTER TABLE "inbound"."PerturbationObservations" DROP COLUMN drainage_structures;
ALTER TABLE "inbound"."PerturbationObservations" DROP COLUMN fencing;
ALTER TABLE "inbound"."PerturbationObservations" ADD COLUMN drainage_structures boolean; 
ALTER TABLE "inbound"."PerturbationObservations" ADD COLUMN fencing boolean; 
COMMENT ON COLUMN "inbound"."PerturbationObservations".drainage_structures IS E'(waar/onwaar) tubes, ditches, canals, pits';
COMMENT ON COLUMN "inbound"."PerturbationObservations".fencing IS E'(waar/onwaar) barbed or electric wire';
UPDATE "inbound"."PerturbationObservations" SET drainage_structures = FALSE, fencing = FALSE;


DROP VIEW IF EXISTS  "inbound"."FieldWork" CASCADE;

ALTER TABLE "inbound"."MeteorolObservations" ALTER COLUMN exceptional TYPE varchar USING exceptional::varchar;
UPDATE "inbound"."MeteorolObservations" SET exceptional = 'hittegolf' WHERE exceptional = 'true';
UPDATE "inbound"."MeteorolObservations" SET exceptional = NULL WHERE exceptional = 'false';


```


request 20260803:
```sql
ALTER TABLE "inbound"."LenticVisits" ADD COLUMN waterlevel_elevation_mtaw double precision; 
COMMENT ON COLUMN "inbound"."LenticVisits".waterlevel_elevation_mtaw IS E'elevation of the water level (mTAW)';

```