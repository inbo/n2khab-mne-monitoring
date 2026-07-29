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



## input
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
- [ ] Bladinval *(%)*
- [ ] Beschaduwing *(%)*
- [ ] Emergente *vegetatie* (bedekking %)
- [ ] Pleustofyten (bedekking %)
- [ ] Nymphaeiden (bedekking %)
- [ ] *Submerse vegetatie (bedekking %)*
- [ ] *Submerse vegetatie (PVI) *--> dit in plaats van verticale projectie
- [ ] infestatie
- [ ] Metaphyton (bedekking %)
- [ ] Open water (bedekking %) --> dit in plaats van bedekkingsgraad
- [ ] *Maximale diepte (cm) *
- [ ] *Kwelinvloed (niet, iriserende film, roestbruinig water of slib) *--> nieuw
- [ ] element
- [ ] Connectiviteit *(gesloten, instroom, doorstroom, overstroomd)*
- [ ] *Grof organisch materiaal (weinig, matig, veel) *--> dit in plaats van
- [ ] "waterbodem".
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

- [ ] *Koeienvlaaien* (TRUE/FALSE)
- [ ] *Andere dierlijke mest* (TRUE/FALSE) --> "dierlijke mest" in huidige versie
- [ ] opdelen in twee elementen (zijnde "koeienvlaaien" en "andere dierlijke mest")
- [ ] Grazers (TRUE/FALSE)
- [ ] *Trampling* (TRUE/FALSE)
- [ ] (Intensieve) veehouderij *in de buurt* (TRUE/FALSE)
- [ ] *Akkers in de buurt* (TRUE/FALSE)
- [ ] Recente bemesting *in de buurt* (TRUE/FALSE)
- [ ] Drukke verkeerswegen* in de buurt *(TRUE/FALSE)
- [ ] *Industrie in de buurt *(TRUE/FALSE)
- [ ] Vis (TRUE/FALSE)
- [ ] *Vogels* (TRUE/FALSE)
- [ ] *Vogeluitwerpselen* (TRUE/FALSE)
- [ ] Bever (TRUE/FALSE)
- [ ] *Invasieve soorten* (TRUE/FALSE)

- [ ] Oeverversteviging (TRUE/FALSE)
- [ ] Drainagestructuren (buizen, grachten) (TRUE/FALSE)
- [ ] Prikkel- of schrikdraad (TRUE/FALSE)
- [ ] *Extra* *opmerkingen (vb. intensiteit van verstoring, ID van soorten,
- [ ] andere verstoringen)*
- [ ] *Foto observatie (optioneel)*

De velden "landgebruik observatie" en "sectoriële milieudrukken" in de
huidige laag "landgebruik" mag je weglaten.

*(6) Bij "meteo" mogen volgende velden genoteerd worden, graag in
onderstaande volgorde (tekstuele aanpassingen t.o.v. huidige versie staan
in het vet, wil je deze ook toevoegen, aub?)*

- [ ] *neerslag op moment van staalname* (true/false).
- [ ] Indien TRUE, laat opties zien "*soort neerslag (regen, hagel,
- [ ] sneeuw)*" en "*intensiteit
- [ ] (licht, matig, zwaar)*"
- [ ] Indien FALSE, laat optie zien "*actuele bewolking (zonnig, licht, zwaar,
- [ ] betrokken, mistig)*"
- [ ] luchttemperatuur (°C)
- [ ] *actuele windcondities (geen, zwak, matig, sterk)*
- [ ] *weer afgelopen 48 uur *
- [ ] *extra opmerkingen (vb. extreme weersomstandigheden)*
- [ ] *foto observatie (optioneel)*
- [ ] ? ijslaag

Het huidige veld "actueel weer" mag eigenlijk weggelaten worden.

*(7) Bij elke laag stonden tevens volgende elementen:*

teamlid observerend
datum bezoek
locatie
