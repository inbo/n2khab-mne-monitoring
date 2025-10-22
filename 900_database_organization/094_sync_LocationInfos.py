#!/usr/bin/env python3

# Testing:
#   UPDATE "outbound"."LocationInfos" SET accessibility_inaccessible = TRUE, log_update = current_timestamp WHERE locationinfo_id = 1;

#  ALTER TABLE "outbound"."LocationInfos" DROP CONSTRAINT "LocationInfos_pkey" CASCADE;
#
#
#


import sys as SYS
import numpy as NP
import pandas as PD
import MNMDatabaseToolbox as DTB
import geopandas as GPD

raise(Exception("DON'T USE! There is an issue with this script and poc update timestamps. A better way is on the way."))

# currently,
# - reserved watina codes are overwritten loceval -> mnmgwdb
# - ... but recovery_info is overwritten other direction.

# TODO to manually update LocationInfos, do:
"""
-- @loceval
\COPY (
SELECT grts_address, recovery_hints
FROM "outbound"."LocationInfos"
WHERE recovery_hints IS NOT NULL
) TO '/data/locinfos_loceval.csv' With CSV DELIMITER ',' HEADER;

... and then in LibreOffice calc
="UPDATE ""outbound"".""LocationInfos"" SET recovery_hints = E'"&B2&"' WHERE grts_address = "&A2&" AND recovery_hints IS NULL;"

UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel bamboestok, ZO van plukje zilte rus' WHERE grts_address = 5234357 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel, klei met zand' WHERE grts_address = 5455541 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok gele meetnagel ' WHERE grts_address = 5979829 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel en blauwe bamboestok, juist ten westen veenmosbult. ' WHERE grts_address = 4234358 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok,  staat niet exact ivm beverburcht' WHERE grts_address = 190802 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok gele meetnagel ' WHERE grts_address = 196022 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel. MiddelMiddelpunt zit eigenlijk op liggende stam, meetnagel ernaast geplaatst. Laarzen, ondiep grondwater' WHERE grts_address = 837618 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele, net ten zuiden greppeltje. Zeker grondwater binnen bereik geurende winter' WHERE grts_address = 9262 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok gele meetnagel ' WHERE grts_address = 1660081 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok gele meetnagel ' WHERE grts_address = 1676465 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 769793 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 366225 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Witte meetnagel, blauwe bamboestok. Op rand gemaaid stuk' WHERE grts_address = 369974 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok,  ca 2 m van  water thv zwarte els' WHERE grts_address = 780114 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok gele meetnagel ' WHERE grts_address = 2593969 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel,  blauwe bamboestok in elzenopslag. Grondwater ondiep' WHERE grts_address = 51431410 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel, blauwe bamboestok ' WHERE grts_address = 832158 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe,  dunne bamboestok. Droog, grondwater zakt vrij diep' WHERE grts_address = 84598 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok in greppel' WHERE grts_address = 12353 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Dunne bamboestok. Midden tussen wilgen-elzeneilandje en "vasteland". Extreem nat, waadpak, best 2 personen' WHERE grts_address = 41746 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok,  gele meetnagel,' WHERE grts_address = 53662 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel,  blauwe bamboestokb.Broekbos overstroomd in ' WHERE grts_address = 45526 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok gele meetnagel. Wellicht grondwaterafhankelijk ' WHERE grts_address = 84270 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel  onder struikhei naast zaailing amerikaans. Droog, Maar grondwater wellicht binnenn bereik' WHERE grts_address = 88274 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok, gele meetnagel ' WHERE grts_address = 4313042 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok gele meetnagel ' WHERE grts_address = 3036337 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok (kort),  gele meetnagel ' WHERE grts_address = 11990318 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok gele meetnagel ' WHERE grts_address = 49779889 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 792209 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok,  gele meetnagel ' WHERE grts_address = 51221550 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok  tussen omgevallen es met twee hoofdtakken en snaak van els' WHERE grts_address = 7069106 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel  ca. 1,25 m van rand plagplek' WHERE grts_address = 649522 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok,  gele meetnagel ' WHERE grts_address = 656798 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel, bamboestok. 1,5 m ZZW van beuk. Veel grind,' WHERE grts_address = 7151026 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok.  tegen es DBH 5 CM' WHERE grts_address = 11256498 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok,  gele meet. meetnagel locatie onnauwkeurig ' WHERE grts_address = 13688242 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel,   1m ten zuidoosten tweestammige dikke berk' WHERE grts_address = 1485106 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel,  ca 0,5 m no van zuidelijke wal' WHERE grts_address = 51429121 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 253621 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gemarkeerd met twee paaltjes' WHERE grts_address = 905382 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok, dichtst bij knotwilgje' WHERE grts_address = 31875858 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe sparrentak. Laarzen' WHERE grts_address = 709330 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 44955281 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok, gele  meetnagel ' WHERE grts_address = 3796785 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel ' WHERE grts_address = 120110 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok en gele meetnagel. In stoof van zwarte els, 5 m zw van eik' WHERE grts_address = 6417454 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok,  gele meetnagel op dijkje bij perceelsrand. Laarzen' WHERE grts_address = 121042 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel.  Wellicht grondwaterafhankelijk.' WHERE grts_address = 118830 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel, droog/laarzen.  Grondwater zakt vrij diep weg' WHERE grts_address = 127710 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauw op dode berk, gele meetnagel tak. Laarzen' WHERE grts_address = 219694 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok gele meetnagel.  Laarzen.' WHERE grts_address = 12532662 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe tak, gele meetnagel,' WHERE grts_address = 928050 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel en blauwe' WHERE grts_address = 45726 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'2 bamboe, 1 wit schijfje. Tussen zwarte bes en meidoorn.' WHERE grts_address = 47238 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok,  gele meetnagel. Opgelet, meetpunt voor 2 types' WHERE grts_address = 131806 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel,  op zuidhelling donkje' WHERE grts_address = 3559134 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel, blauwe tak op de lijn tussen twee peilbuizen' WHERE grts_address = 743982 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 1202926 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel ' WHERE grts_address = 505902 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok, gele meetnagel ' WHERE grts_address = 1205598 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok, gele meetnagel.  in vangkraal, plaatsing te bespreken met boswachter' WHERE grts_address = 2987185 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok,  gele meetnagel,  in stukje met snavelzegge (die grote blauwgrijze :) )' WHERE grts_address = 5471538 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok gele meetnagel. Grondwaterafhankelijk ' WHERE grts_address = 3818642 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 44765877 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok waadpak, wellicht best met 2 personen' WHERE grts_address = 696182 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe tak, gele bamboestok. Tegen bosrand op koeienpaadje, dus wellicht omvergelopen' WHERE grts_address = 53438770 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel, ongeveer halfweg k bewateringsgeul en gracht' WHERE grts_address = 48043282 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok,  gele meetnagel. Veel strooisel' WHERE grts_address = 4229394 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel die wat boven maaiveld uitsteekt' WHERE grts_address = 6326546 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel.  Droog, maar grondwater binnen bereik' WHERE grts_address = 102706 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok gele meetnagel, net ten zuiden pitrisbult' WHERE grts_address = 31682546 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok. Net ten N wilgenkoepel' WHERE grts_address = 53438326 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel en blauwe bamboestok ' WHERE grts_address = 211193 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel,  bultje met veel dophei' WHERE grts_address = 826486 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Twee blauwe stokken gele meetnagel ' WHERE grts_address = 52009518 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok,  gele meetnagel' WHERE grts_address = 7733982 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel  1 m O van duintje met hoge struikhei' WHERE grts_address = 176862 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok,  gele meetnagel,  net ten noorden dikke strooiselhoop. Lukt met laarzen als je voorzichtig bent. Lastige draad rondom. 2 personen' WHERE grts_address = 13822258 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele  meetnagel,  2 m boven gracht' WHERE grts_address = 1971474 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe stok, gele meetnagel ' WHERE grts_address = 1677870 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok gele meetnagel ' WHERE grts_address = 50042033 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 50133169 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok,  naast tweestammige es. Stukjes met kalkneerslag vermijden (7220)' WHERE grts_address = 3726770 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel  en blauwe bamboestok' WHERE grts_address = 37049 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok waadpak, wellicht best met 2 personen. Toegang makkelijkst vanaf noord, zie punt.' WHERE grts_address = 31496054 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe eikentak (bamboe op ð). Geen meetnagel ivm maaibeheer op zachtz bodem. Punt is waar stok in de grond stopt. Net ten zw iemand anders bamboestok. Laarzen met voorzichtigheid,  anders lieslaarzen/waadpak' WHERE grts_address = 31536054 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel ' WHERE grts_address = 39213362 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Witte meetnagel ' WHERE grts_address = 40434990 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok, gele meetnagel ' WHERE grts_address = 41313630 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel ' WHERE grts_address = 42070750 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel.  Droog, maar grondwater binnen bereik' WHERE grts_address = 42651954 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Witte meetnagel' WHERE grts_address = 43623186 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok ' WHERE grts_address = 48578229 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel  blauwe bamboestok ' WHERE grts_address = 50137201 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok gele meetnagel ' WHERE grts_address = 50476209 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel,  waadpak gaat eenvoudigst zijn om langs zuid door de gracht te komen. Erg mooi ontwikkeld voorbeeld van het habitattype! ' WHERE grts_address = 50325810 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe stok, dichtbij gasleiding' WHERE grts_address = 50354734 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok ' WHERE grts_address = 50811954 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Korte bamboestok, geÃ¶e meetnagel. Circa 2,5 m ten NO wandelpad' WHERE grts_address = 50988446 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel ' WHERE grts_address = 50725598 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok gele meetnagel. Noeilijk af te bakenen, zie uitleg bij celkartering' WHERE grts_address = 1922225 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok,  paaltje tekort' WHERE grts_address = 1938609 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel en blauwe bamboestok ' WHERE grts_address = 51598638 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel,  in rand van hogere en meer vergraste zone' WHERE grts_address = 9300274 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok (dun)' WHERE grts_address = 57174322 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel bamboestok.' WHERE grts_address = 540341 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok gele meetnagel ' WHERE grts_address = 81985 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel in slenk' WHERE grts_address = 261854 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe,  dunne bamboestok. Droog, grondwater zakt vrij diep' WHERE grts_address = 871030 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok, gele meetnagel ' WHERE grts_address = 3676246 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel,  ca 0,5 m no van zuidelijke wal' WHERE grts_address = 48897 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 1035478 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel, droog/laarzen.  Grondwater zakt vrij diep weg' WHERE grts_address = 1176286 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok gele meetnagel ' WHERE grts_address = 450229 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel' WHERE grts_address = 472065 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok ' WHERE grts_address = 480306 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok,  juist in gagelstruik' WHERE grts_address = 4496502 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'GelGele meetnagel blauwe bamboestok,  naast gagelstruikje ' WHERE grts_address = 105458 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok, gele meetnagel,  zo goed als onder raster. Wellicht diep grondwater, maar stuwwatertafel in de winter. Stenig' WHERE grts_address = 1032326 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok gele meetnagel ' WHERE grts_address = 1062930 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel en blauwe bamboestok ' WHERE grts_address = 46177398 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok,  juist ten zuiden rijpad.  Grondwater diep, mergel ondiep, veel silex' WHERE grts_address = 53288370 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Kort bamboestokje, gele meetnagel ' WHERE grts_address = 500782 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 1818369 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 45029009 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 10640110 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel' WHERE grts_address = 47553522 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok. 40 cm water!' WHERE grts_address = 1013294 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel bWellicht  grondwaterafhankelijk ' WHERE grts_address = 74542 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok gele meetnagel, peilbuis niet tussen zilte rus plaatsen' WHERE grts_address = 3202741 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok ' WHERE grts_address = 3554997 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok,  gele meetnagel ' WHERE grts_address = 236530 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel en blauwe bamboestok' WHERE grts_address = 44604534 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok gele meetnagel ' WHERE grts_address = 3858101 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok' WHERE grts_address = 3664630 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel, blauwe  bamboestok. Ca. 1,5 m van gemaaid pad door het riet' WHERE grts_address = 46172434 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel  blauwe bamboestok,  naast door everzwijnen omgewoeld stukje' WHERE grts_address = 9488370 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel  op kaal stukje grond, blauwe bamboestok. Lemige bodem, grondwater relatief  Check Nederlandse grens met RTK. Punt ligt net binnen landsgrenzen' WHERE grts_address = 53206450 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok en gele meetnagel. In stoof van zwarte els, 5 m zw van eik' WHERE grts_address = 1999406 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'2 bamboe, 1 wit schijfje. Tussen zwarte bes en meidoorn.' WHERE grts_address = 4241542 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok,  gele meetnagel op dijkje bij perceelsrand. Laarzen' WHERE grts_address = 4315346 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel en blauwe bamboestok ' WHERE grts_address = 1134841 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 4447925 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok,  gele meetnagel,' WHERE grts_address = 4772254 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel, blauwe bamboestok ' WHERE grts_address = 6075038 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel' WHERE grts_address = 6092977 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Midden op het veld' WHERE grts_address = 1280278 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 9424086 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Dunne bamboestok. Midden tussen wilgen-elzeneilandje en "vasteland". Extreem nat, waadpak, best 2 personen' WHERE grts_address = 9478930 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauw op dode berk, gele meetnagel tak. Laarzen' WHERE grts_address = 9525806 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel  ca. 1,25 m van rand plagplek' WHERE grts_address = 10152242 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok, gele meetnagel ' WHERE grts_address = 10655830 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok,  maar grote grazers. ' WHERE grts_address = 306162 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok,  staat niet exact ivm beverburcht' WHERE grts_address = 12773714 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok (kort),  gele meetnagel ' WHERE grts_address = 13038894 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 21167406 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 4632918 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Witte meetnagel' WHERE grts_address = 6923026 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel in slenk' WHERE grts_address = 14070494 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel,  in rand van hogere en meer vergraste zone' WHERE grts_address = 14543154 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe stok gele meetnagel bij boomstronkje' WHERE grts_address = 15538734 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 15595153 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok,  gele meetnagel ' WHERE grts_address = 16470006 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok ' WHERE grts_address = 27369590 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 27584145 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok' WHERE grts_address = 29329682 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok ' WHERE grts_address = 29769397 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Mo eilijk terug te vinden, neem rtk gps mee. Bamboestokje gebroken... korte bamboestok, gele meetnagel. Bijkomend gemarkeerd met wilgentak' WHERE grts_address = 9431346 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel (onder water ) blauwe bamboestok' WHERE grts_address = 53184786 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel, stokjes op, sorry' WHERE grts_address = 17262898 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gemarkeerd met twee paaltjes' WHERE grts_address = 17682598 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel en blauwe bamboestok ' WHERE grts_address = 17912057 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel bamboestok, ZO van plukje zilte rus' WHERE grts_address = 19914421 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe stok, dichtbij gasleiding' WHERE grts_address = 20994606 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel, geen bamboestok wegens koeien. Zout!' WHERE grts_address = 21323197 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel,   1m ten zuidoosten tweestammige dikke berk' WHERE grts_address = 35039538 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel (onder water ) blauwe bamboestok' WHERE grts_address = 36407570 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok ' WHERE grts_address = 37843062 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel,  waadpak gaat eenvoudigst zijn om langs zuid door de gracht te komen. Erg mooi ontwikkeld voorbeeld van het habitattype! ' WHERE grts_address = 43182386 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Bamboestok gele meetnagel,  naast' WHERE grts_address = 10305 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Kort blauw bamboestokje, gele meetnagel ' WHERE grts_address = 943826 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Kort bamboestokje, gele meet. Laarzen, grondwater zakt zeer ondiep weg' WHERE grts_address = 959958 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel  blauwe bamboestok. Naast grote schuinhangende schietwilg' WHERE grts_address = 198137 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Klein dun blauw bamboestokje, gele meetnagel ' WHERE grts_address = 1468114 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe stok gele meetnagel bij boomstronkje' WHERE grts_address = 72238 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok,  vlak ten ZO van duidelijk loopspoor' WHERE grts_address = 49692341 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel, geen bamboestok wegens koeien. Zout!' WHERE grts_address = 49896893 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok,  gele meetnagel, makkelijkst te bereiken vanaf noord' WHERE grts_address = 4026486 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok' WHERE grts_address = 4163858 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok. Laarzen ' WHERE grts_address = 7958646 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel tussen witte snavelbies' WHERE grts_address = 2136622 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 3185198 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel ' WHERE grts_address = 1665330 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel, Ca 50 cm van het pad' WHERE grts_address = 1736754 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 299701 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel.  Slecht internet. Wellicht niet grondwaterafhankelijk. Sleutel voor slagboom te vragen aan boswachter. Buis niet op ruimingspiste.' WHERE grts_address = 355910 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel, stokjes op, sorry' WHERE grts_address = 485682 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel ' WHERE grts_address = 37113566 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok ' WHERE grts_address = 51474550 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok' WHERE grts_address = 518902 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok,  dun, steekt juist boven vegetqtie uit. Geen meetnagel ivm indrukbare bodem en maaibalk. Gaat met laarzen mits voorzichtig en wat rondlopen via zuidkant. Broedplek kraanvogels!' WHERE grts_address = 670646 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Blauwe bamboestok gele meetnagel. MiddelMiddelpunt zit eigenlijk op liggende stam, meetnagel ernaast geplaatst. Laarzen, ondiep grondwater' WHERE grts_address = 23906290 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok ' WHERE grts_address = 2137206 AND recovery_hints IS NULL;
UPDATE "outbound"."LocationInfos" SET recovery_hints = E'Gele meetnagel blauwe bamboestok ' WHERE grts_address = 2203766 AND recovery_hints IS NULL;


"""


commandline_args = SYS.argv
if len(commandline_args) > 1:
    suffix = commandline_args[1]
else:
    # suffix = ""
    suffix = "-testing"
    # suffix = "-staging"
suffix = "-testing" # TODO safety net

print("|"*64)
print(f"going to sync LocationInfos between *loceval{suffix}* and *mnmgwdb{suffix}*. \n")

base_folder = DTB.PL.Path(".")

print(f"login to *loceval{suffix}*:")
loceval = DTB.ConnectDatabase(
    base_folder/"inbopostgis_server.conf",
    connection_config = f"loceval{suffix}"
    )

print(f"login to *mnmgwdb{suffix}*:")
mnmgwdb = DTB.ConnectDatabase(
    base_folder/"inbopostgis_server.conf",
    connection_config = f"mnmgwdb{suffix}"
    )

print("Thank you. Proceeding...")


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### load data
#///////////////////////////////////////////////////////////////////////////////

query = """
    SELECT *
    FROM "{schema:s}"."{table:s}";
"""
# print(query.format(schema = "metadata", table = "LocationInfos"))


### source
source_locations = GPD.read_postgis( \
    query.format(schema = "metadata", table = "Locations"), \
    con = loceval.connection, \
    geom_col = "wkb_geometry" \
)

source_data = PD.read_sql_table( \
    "LocationInfos", \
    schema = "outbound", \
    con = loceval.connection \
)

# print(source_data.sample(3).T)
# print(source_data.loc[source_data["grts_address"].values == 23238, :].T)


### target
target_locations = GPD.read_postgis( \
    query.format(schema = "metadata", table = "Locations"), \
    con = mnmgwdb.connection, \
    geom_col = "wkb_geometry" \
)

target_data = PD.read_sql_table( \
    "LocationInfos", \
    schema = "outbound", \
    con = mnmgwdb.connection \
)

# print(target_data.sample(3).T)


### link replacements
lookup_cols = ["grts_address", "grts_address_replacement"]
target_replacements = PD.read_sql( \
    query.format(schema = "archive", table = "ReplacementData"), \
    con = mnmgwdb.connection, \
)
# replacement_lookup = target_replacements.loc[:, lookup_cols] \
#     .drop_duplicates() \
#     .sort_values(lookup_cols)


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### Replacements in Loceval
#///////////////////////////////////////////////////////////////////////////////
target_grts = set(target_data["grts_address"].values)
source_grts = set(source_data["grts_address"].values)
# print(list(sorted(map(int, source_grts))))
replacement_grts = set(target_replacements["grts_address_replacement"].values)

source_missing_grts = list(replacement_grts - source_grts)
target_missing_grts = list(replacement_grts - target_grts)
# TODO ignoring the latter for now: either fully replaced, or not scheduled yet

def DuplicateTableRow(
        db,
        schema,
        table_key,
        identifier_dict,
        index_columns,
        index_newvalues = None,
        one_unique_line = False
    ):
    # db = loceval
    # schema = "outbound"
    # table_key = "LocationInfos"
    # identifier_dict = {"grts_address": 51429121}
    # index_columns = ["locationinfo_id", "grts_address"]
    # index_newvalues = [latest_locinfo_id, 48897]

    print(f"duplicating {identifier_dict} ==> {list(zip(index_columns, index_newvalues))}.")

    table_namestring = f'"{schema}"."{table_key}"'
    existing_data = PD.read_sql(f"""
        SELECT * FROM {table_namestring};
        """,
        con = db.connection
    )

    if index_newvalues is None:
        index_newvalues = \
            [int(existing_data[icol].max()) + 1 for icol in index_columns]
    index_newstring = ", ".join( map(str, index_newvalues))

    columns = [col for col in existing_data.columns
               if col not in index_columns]

    columnstring = ", ".join(columns)

    identifier_string = " AND ".join(
        [f"{idcol} = {idval}" for idcol, idval in identifier_dict.items()]
        )

    insert_command = f"""
        INSERT INTO {table_namestring} ({", ".join(index_columns)}, {columnstring})
        SELECT {index_newstring}, {columnstring}
        FROM {table_namestring}
        WHERE {identifier_string}
    """
    if one_unique_line:
        insert_command += f"""
        ORDER BY log_update DESC, {", ".join(index_columns)}
        LIMIT 1
        """
    insert_command += f"""
        ;
    """

    DTB.ExecuteSQL(db, insert_command, verbose = True, test_dry = False)

### duplicate rows in source
source_infos_to_duplicate = target_replacements.loc[
    [grts in source_missing_grts
     for grts in target_replacements["grts_address_replacement"].values
     ], ["grts_address", "type", "grts_address_replacement"]] \
    .astype({"grts_address": int, "grts_address_replacement": int}) \
    .set_index("grts_address_replacement", inplace = False)


# latest_locinfo_id = int(PD.read_sql(
#     """
#     SELECT locationinfo_id FROM "outbound"."LocationInfos"
#     ORDER BY locationinfo_id DESC
#     LIMIT 1;
#     """,
#     con = loceval.connection
#    ).values[0, 0]) + 0
latest_ogc_fid = source_locations["ogc_fid"].max()
latest_location_id = source_locations["location_id"].max()
latest_locinfo_id = source_data["locationinfo_id"].max()

clean_sqlstr = lambda txt: txt.replace("'", "")
val_to_geom_point = lambda val: "NULL" if PD.isna(val) else f"'{clean_sqlstr(str(val))}'"

for grts_new, row in source_infos_to_duplicate.iterrows():
    # grts_new = source_infos_to_duplicate.index.values[0]
    # row = source_infos_to_duplicate.iloc[0, :]
    grts_old = row["grts_address"]
    # print(grts_old, grts_new)

    latest_ogc_fid += 1
    latest_location_id += 1
    latest_locinfo_id += 1

    # on loceval, there can be new grts (replacement) which also require a Location
    location_id = source_locations.loc[
        grts_new == source_locations['grts_address'].values,
        'location_id']
    if len(location_id) == 0:
        geom_str = val_to_geom_point(source_locations.loc[
            source_locations['grts_address'].values == grts_old,
            "wkb_geometry"].values[0])

        insert_command = f"""
            INSERT INTO "metadata"."Locations" (ogc_fid, location_id, wkb_geometry, grts_address)
            VALUES ({latest_ogc_fid}, {latest_location_id}, {geom_str}, {grts_new});
        """
        DTB.ExecuteSQL(loceval, insert_command, verbose = True, test_dry = False)

        location_id = latest_location_id
    else:
        location_id = int(location_id.values[0])

    DuplicateTableRow(
        db = loceval,
        schema = "outbound",
        table_key = "LocationInfos",
        identifier_dict = {"grts_address": grts_old},
        index_columns = ["grts_address", "locationinfo_id", "location_id"],
        index_newvalues = [grts_new, latest_locinfo_id, location_id]
       )



### duplicate rows in target
target_infos_to_duplicate = target_replacements.loc[
    [grts in target_missing_grts
     for grts in target_replacements["grts_address_replacement"].values
     ], ["grts_address", "type", "grts_address_replacement"]] \
    .astype({"grts_address": int, "grts_address_replacement": int}) \
    .set_index("grts_address_replacement", inplace = False)


latest_locinfo_id = target_data["locationinfo_id"].max()

for grts_new, row in target_infos_to_duplicate.iterrows():
    # grts_new = source_infos_to_duplicate.index.values[0]
    # row = source_infos_to_duplicate.iloc[0, :]
    grts_old = row["grts_address"]
    # print(grts_old, grts_new)

    latest_locinfo_id += 1

    DuplicateTableRow(
        db = mnmgwdb,
        schema = "outbound",
        table_key = "LocationInfos",
        identifier_dict = {"grts_address": grts_old},
        index_columns = ["grts_address", "locationinfo_id"],
        index_newvalues = [grts_new, latest_locinfo_id]
       )


# in target, if the replacement is complete,
# there is no need to keep the outdated association with the old Location

detached_infos = f"""
DELETE
FROM "outbound"."LocationInfos"
WHERE locationinfo_id NOT IN (
  SELECT DISTINCT locationinfo_id
  FROM "outbound"."LocationInfos" INFOS, "metadata"."Locations" LOCS
  WHERE INFOS.grts_address = LOCS.grts_address
    AND INFOS.location_id = LOCS.location_id
)
;
"""

DTB.ExecuteSQL(mnmgwdb, detached_infos, verbose = True, test_dry = False)


# Duplication is only useful

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#### Match LocationInfos
#///////////////////////////////////////////////////////////////////////////////

# re-load source and target data
source_data = PD.read_sql_table( \
    "LocationInfos", \
    schema = "outbound", \
    con = loceval.connection \
)


target_data = PD.read_sql_table( \
    "LocationInfos", \
    schema = "outbound", \
    con = mnmgwdb.connection \
)

### apply lookup
## source
# source_data = source_data \
#     .join( \
#         replacement_lookup.set_index("grts_address"),
#         how = "left",
#         on = "grts_address"
#     )
# source_data = source_data.reset_index(drop = True)

# source_data.loc[NP.logical_not(PD.isna(source_data["grts_address_replacement"])), :]
# for idx, row in source_data.iterrows():
#     grts_address_replacement = source_data.loc[idx, "grts_address_replacement"]
#     if PD.isna(grts_address_replacement):
#         source_data.loc[idx, "grts_address_replacement"] = source_data.loc[idx, "grts_address"]
#
# source_data["grts_address_replacement"] = source_data["grts_address_replacement"].astype(int)
# source_data = source_data.rename(columns = {"grts_address": "grts_address_original"})


## target
# target_data.loc[target_data["grts_address"].values == 23238, :]

# outer = source_data.loc[:, ["grts_address"]] \
#     .merge(target_data.loc[:, ["grts_address"]], \
#            how='outer', indicator=True)
# source_grts_to_target = outer[(outer._merge=='left_only')].drop('_merge', axis=1)

# target_locations.loc[target_locations["grts_address"].values == 23238, :]
# target_locations
# target_data.columns
# target_data["grts_address_replacement"] = target_data["grts_address"].values
# target_data = target_data.drop(columns = "grts_address")
# target_data = target_data.rename(columns = {"grts_address": "grts_address_replacement"})

# !!!!!
# target_data = target_data \
#     .join( \
#         replacement_lookup.set_index("grts_address_replacement"),
#         how = "left",
#         on = "grts_address_replacement"
#     )

# target_data = target_data.reset_index(drop = True)
# # target_data.loc[NP.logical_not(PD.isna(target_data["grts_address_replacement"])), :]
# for idx, row in target_data.iterrows():
#     grts_address = target_data.loc[idx, "grts_address"]
#     if PD.isna(grts_address):
#         target_data.loc[idx, "grts_address"] = target_data.loc[idx, "grts_address_replacement"]

# target_data["grts_address"] = target_data["grts_address"].astype(int)
# target_data = target_data.rename(columns = {"grts_address": "grts_address_original"})


### associate data

# source_data.loc[:, ["locationinfo_id", "grts_address"]].sort_values("grts_address").to_csv("dumps/find_locationinfos.csv")
# source_data.loc[[int(grts) == 23238 for grts in source_data["grts_address"].values], :]
# target_data.loc[target_data["grts_address"].values == 6314694, :]
common_grts = source_data.loc[:, ["grts_address"]] \
    .merge(target_data.loc[:, ["grts_address"]], \
           how='inner', indicator=False)

missing_grts = source_data.loc[:, ["grts_address"]] \
    .merge(target_data.loc[:, ["grts_address"]], \
           how='outer', indicator=True)
missing_target = missing_grts[(missing_grts._merge=='left_only')].drop('_merge', axis=1)
missing_source = missing_grts[(missing_grts._merge=='right_only')].drop('_merge', axis=1)


source_data = source_data.set_index(["grts_address"])
target_data = target_data.set_index(["grts_address"])

# source_new = target_data.loc[[missing_source.iloc[i, :] for i in range(missing_source.shape[0])], :]
# target_new = source_data.loc[[missing_target.iloc[i, :] for i in range(missing_target.shape[0])], :]
source_new = target_data.loc[missing_source["grts_address"].values, :]
target_new = source_data.loc[missing_target["grts_address"].values, :]


source_new = source_new.reset_index(drop = False)
target_new = target_new.reset_index(drop = False)

# some columns are mnmgwdb only (e.g. watina code)
common_columns = list(set(target_new.columns).intersection(set(source_new.columns)))
source_new = source_new.loc[:, common_columns]
# source_new = source_new.rename(columns = {"grts_address_original": "grts_address"}).drop(columns = "grts_address_replacement")
target_new = target_new.loc[:, common_columns]
# target_new = target_new.rename(columns = {"grts_address_replacement": "grts_address"}).drop(columns = "grts_address_original")
source_new = source_new.drop(columns = "locationinfo_id")
target_new = target_new.drop(columns = "locationinfo_id")

clean_sqlstr = lambda txt: txt.replace("'", "")
noop = lambda val: val
val_to_bool = lambda val: "NULL" if PD.isna(val) else ("TRUE" if bool(val) else "FALSE")
val_to_datetime = lambda val: "NULL" if PD.isna(val) else f"'{str(val)}'"
val_to_int = lambda val: "NULL" if PD.isna(val) else str(int(val))
val_to_string = lambda val: "NULL" if PD.isna(val) else f"'{clean_sqlstr(val)}'"

col_change_functions = {
    "grts_address": val_to_int,
    "log_creator": val_to_string,
    "log_creation": val_to_datetime,
    "log_user": val_to_string,
    "log_update": val_to_datetime,
    "landowner": val_to_string,
    "accessibility_inaccessible": val_to_bool,
    "accessibility_revisit": val_to_datetime,
    "recovery_hints": val_to_string,
    }


print("\\"*64)
print(f"Inserting new into **{loceval.config['database']}**:")
# insert_source = source_new.iloc[0, :]
for _, insert_source in source_new.iterrows():

    insert_value_dict = {k: col_change_functions.get(k, noop)(v)
        for k, v in insert_source.to_dict().items()}
    locationid_lookup_query = f"""
        SELECT DISTINCT location_id
        FROM "metadata"."Locations"
        WHERE grts_address = {insert_value_dict["grts_address"]}
        ;
    """
    locationid = PD.read_sql(
        locationid_lookup_query,
        con = loceval.connection
    )
    if NP.multiply(*locationid.shape) == 0:
        print(f"""GRTS address not found in {loceval.config["database"]}::"metadata"."Locations": {insert_value_dict["grts_address"]}""")
        continue

    locationid = locationid.iloc[0, 0]

    insert_value_dict["location_id"] = str(int(locationid))

    locationinfo_next = int(PD.read_sql(
        """
               SELECT locationinfo_id FROM "outbound"."LocationInfos"
               ORDER BY locationinfo_id DESC
               LIMIT 1;
           """,
        con = loceval.connection
       ).values[0, 0]) + 1
    insert_value_dict["locationinfo_id"] = str(int(locationinfo_next))

    insert_command = """
      INSERT INTO "outbound"."LocationInfos"
      ( locationinfo_id,
        log_creator, log_creation, log_user, log_update,
        location_id, grts_address,
        landowner, accessibility_inaccessible,
        accessibility_revisit, recovery_hints
      ) VALUES ( {locationinfo_id},
        {log_creator}, {log_creation}, {log_user}, {log_update},
        {location_id}, {grts_address},
        {landowner}, {accessibility_inaccessible},
        {accessibility_revisit}, {recovery_hints}
      );
    """.format(**insert_value_dict)
    # print(insert_command)
    DTB.ExecuteSQL(
        loceval,
        insert_command,
        verbose = True
       )


print("...done." + "\n"*3)
print("\\"*64)
print(f"Inserting new into **{mnmgwdb.config['database']}**:")
# insert_target = target_new.iloc[0, :]
for _, insert_target in target_new.iterrows():

    insert_value_dict = {k: col_change_functions.get(k, noop)(v)
        for k, v in insert_target.to_dict().items()}
    locationid_lookup_query = f"""
        SELECT DISTINCT location_id
        FROM "metadata"."Locations"
        WHERE grts_address = {insert_value_dict["grts_address"]}
        ;
    """
    locationid = PD.read_sql(
        locationid_lookup_query,
        con = mnmgwdb.connection
    )
    if NP.multiply(*locationid.shape) == 0:
        print(f"""GRTS address not found in {mnmgwdb.config["database"]}::"metadata"."Locations": {insert_value_dict["grts_address"]}""")
        continue

    locationid = locationid.iloc[0, 0]

    insert_value_dict["location_id"] = str(int(locationid))

    locationinfo_next = int(PD.read_sql(
        """
               SELECT locationinfo_id FROM "outbound"."LocationInfos"
               ORDER BY locationinfo_id DESC
               LIMIT 1;
           """,
        con = mnmgwdb.connection
       ).values[0, 0]) + 1
    insert_value_dict["locationinfo_id"] = str(int(locationinfo_next))

    insert_command = """
      INSERT INTO "outbound"."LocationInfos"
      ( locationinfo_id,
        log_creator, log_creation, log_user, log_update,
        location_id, grts_address,
        landowner, accessibility_inaccessible,
        accessibility_revisit, recovery_hints
      ) VALUES ( {locationinfo_id},
        {log_creator}, {log_creation}, {log_user}, {log_update},
        {location_id}, {grts_address},
        {landowner}, {accessibility_inaccessible},
        {accessibility_revisit}, {recovery_hints}
      );
    """.format(**insert_value_dict)
    # print(insert_command)

    DTB.ExecuteSQL(
        mnmgwdb,
        insert_command,
        verbose = True
       )


# only keep common grts (which *should* be all)
#

# source_data = source_data.loc[[common_grts.iloc[i, :] for i in range(common_grts.shape[0])], :].reset_index(drop = False)
# target_data = target_data.loc[[common_grts.iloc[i, :] for i in range(common_grts.shape[0])], :].reset_index(drop = False)
source_data = source_data.loc[common_grts["grts_address"].values, :].reset_index(drop = False)
target_data = target_data.loc[common_grts["grts_address"].values, :].reset_index(drop = False)

#perform outer join
accessibility_cols = [ \
    "grts_address",
    "accessibility_inaccessible", "accessibility_revisit",
    "recovery_hints"
   ]
outer = source_data.loc[:, accessibility_cols] \
    .merge(target_data.loc[:, accessibility_cols], \
           how='outer', indicator=True)
# print(outer)

source_to_target = outer[(outer._merge=='left_only')].drop('_merge', axis=1)
# source_to_target = source_to_target.rename(columns = {"grts_address_replacement": "grts_address"}).drop(columns = "grts_address_original")
target_to_source = outer[(outer._merge=='right_only')].drop('_merge', axis=1)
# target_to_source = target_to_source.rename(columns = {"grts_address_original": "grts_address"}).drop(columns = "grts_address_replacement")


def get_timestamp(df, grts, col):
    return(df.loc[df[col] == grts, "log_update"])

get_ts_source = lambda df, grts: get_timestamp(df, grts, "grts_address")
get_ts_target = lambda df, grts: get_timestamp(df, grts, "grts_address")



# if (source_to_target.shape[0] > 0):
source_to_target["source_ts"] = [get_ts_source(source_data, row["grts_address"]).values[0]
                                 for _, row in source_to_target.iterrows() ]

source_to_target["target_ts"] = [get_ts_source(target_data, row["grts_address"]).values[0]
                                 for _, row in source_to_target.iterrows() ]

# TODO if
# row = source_to_target.iloc[0, :]
target_to_source["source_ts"] = [get_ts_target(source_data, row["grts_address"]).values[0]
                                 for _, row in target_to_source.iterrows() ]

target_to_source["target_ts"] = [get_ts_target(target_data, row["grts_address"]).values[0]
                                 for _, row in target_to_source.iterrows() ]

## filter
source_to_target = source_to_target.loc[
    NP.logical_and(
        NP.logical_not(PD.isna(source_to_target["target_ts"].values)),
        source_to_target["target_ts"].values < source_to_target["source_ts"].values
    )
    , :]


target_to_source = target_to_source.loc[
    NP.logical_and(
        NP.logical_not(PD.isna(target_to_source["target_ts"].values)),
        target_to_source["target_ts"].values > target_to_source["source_ts"].values
    )
    , :]

### lookup (replacements)


### create update strings
clean_sqlstr = lambda txt: txt.replace("'", "")

noop = lambda val: val
val_to_bool = lambda val: "NULL" if PD.isna(val) else ("TRUE" if bool(val) else "FALSE")
val_to_datetime = lambda val: "NULL" if PD.isna(val) else f"'{str(val)}'"
val_to_int = lambda val: "NULL" if PD.isna(val) else str(int(val))
val_to_string = lambda val: "NULL" if PD.isna(val) else f"E'{clean_sqlstr(val)}'"

col_change_functions = {
    "accessibility_inaccessible": val_to_bool,
    "accessibility_revisit": val_to_datetime,
    "recovery_hints": val_to_string,
    "grts_address": val_to_int
    }


update_command = """
    UPDATE "outbound"."LocationInfos"
    SET accessibility_inaccessible = {accessibility_inaccessible},
        accessibility_revisit = {accessibility_revisit},
        recovery_hints = {recovery_hints}
    WHERE grts_address = {grts_address};
"""

print("...done." + "\n"*3)
print("/"*64)
print(f"Uploading from **{loceval.config['database']}** to **{mnmgwdb.config['database']}**:")
for _, row in source_to_target.iterrows():
    update_value_dict = {k: col_change_functions.get(k, noop)(v)
        for k, v in row.to_dict().items()}

    DTB.ExecuteSQL(
        mnmgwdb,
        update_command.format(**update_value_dict),
        verbose = True
       )

print("...done." + "\n"*3)
print("\\"*64)
print(f"Uploading from **{mnmgwdb.config['database']}** to **{loceval.config['database']}**:")
for _, row in target_to_source.iterrows():
    update_value_dict = {k: col_change_functions.get(k, noop)(v)
        for k, v in row.to_dict().items()}

    DTB.ExecuteSQL(
        loceval,
        update_command.format(**update_value_dict),
        verbose = True
       )


# TODO there is some potential here for using temporary tables and `UPDATE... SET... FROM... WHERE...;` script.

print("...done." + "\n"*3)
### ARCHIVE
# I did some manual adjustments to avoid loosing previous entries (older than maintenance on other db)
# SELECT * FROM "outbound"."LocationInfos"
# WHERE grts_address =
# 23238
# ;
#
# UPDATE "outbound"."LocationInfos" SET accessibility_revisit = NULL WHERE grts_address =
# 23238
# ;
# 47238
# 905382

print("_"*80)
