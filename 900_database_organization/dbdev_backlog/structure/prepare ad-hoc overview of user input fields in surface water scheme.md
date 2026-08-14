---
aliases:
tags:
  - mnmsurfdb
  - locevaldb
  - structure
  - overview
  - fieldforms
started: 2026-08-14
finished: 2026-08-14
execution:
  - FM
status: true
priority:
---

for meeting #AL #FV #KW #FM  

sheet `mnmsurfdb field forms overview` (can be converted to/fro markdown via [LibreOffice](https://www.libreoffice.org))


## Overview: MNM "LOCEVAL" Data Collection
as of [[timeline/2026-08-14|2026-08-14]]

|   |   |   |   |   |
|---|---|---|---|---|
|**_category_**|**_column_**|**_datatype_**|**_comment_**|**_note_**|
|**technisch/informatief**|||||
||log_user|varchar|(technical) user who modified the entry||
||log_update|timestamp|(technical) timestamp of last modification||
||grts_address|bigint|GRTS address (`final`, i.e. after prior replacements) needed for retainer lookup||
||type|varchar|type, as planned in the sampling procedure||
||activity_group_id|smallint|a link to the activity metadata|LOCEVALTERR or LOCEVALAQ|
||date_start|date|start of the panel activity sequence||
||domain_part|varchar|domain partition||
||is_forest|boolean|flag forest type sample locatione||
||in_mhq_samples|boolean|flag sites used for MHQ||
||has_mhq_assessment|boolean|(temporary) column to filter MHQ polygons||
||mhq_assessment_date|date|date of previous assessment||
||landowner|varchar|reference to the land owner|_rough categories (ANB/natuurpunt/MIL/.../neither)_|
||||||
|**locatieevaluatie**|||||
||teammember_id|smallint|link to the user who performed the visit||
||date_visit|date|date of the field activity||
||type_assessed|varchar|referring to "N2kHabTypes"."type"; any corrections from previous evaluation||
||is_well_developed_type|boolean|register cells which contain a well developed type, for info to adjacent teams/location research||
||gps_type|varchar|which type of GPS was used||
||gps_accuracy_cm|double precision|measurement accuracy of the RTK GPS, expressed in centimeters||
||notes|text|Free text notes from the previous visits||
||photo|varchar|an optional photo of the site or noteworthy thing||
||issues|boolean|highlight issues (use notes to specify)||
||visit_done|boolean|filter column for locations which have already been visited||
||archive_version_id|smallint|(technical) flag archived visits||
||samplingpoint_selection_done|boolean|check whether a point was selected for chemical sampling|_only aquatic types_|
||crassula_was_here|boolean|flag aquatic units which are home to invasive Crassula helmsii|_only aquatic types_|
||||||
|**staalname-doelpunten**|||||
||date_selection|date|the date of sampling point selection (preference for the newest)||
||type|varchar(16)|habitat type||
||notes|text|extra notes about the sampling point||
||photo|varchar|an optional photo of the sampling point and surroundings||
||is_legacypoint|boolean|flag target points imported from legacy list||
||try_first|boolean|prioritize some of the legacy points||
||wkb_geometry||Point geometry (31370 / Lambert 72): target location||
||||||
|**celkarteringen**||||**_indirecte link met GRTS via geometrie_**|
||geometry||Polygon geometry (31370 / Lambert 72)||
||label|varchar|short label to classify the polygon (optional)||
||type|varchar|type (code) of this polygon||
||location|varchar|free reference to the location (database id or grts address)||
||notes|text|extra space for notes||
||||||
|**lokale vervanging**||||_(conditional visibility)_|
||replacement_ongoing|boolean|transient column to filter a view for ongoing replacements||
||replacement_reason|text|explanation for replacement choice, e.g. inaccessibility||
||replacement_permanence|text|whether or not the location is permanently unavailable||
||is_replaced|boolean|indicator whether we used a replacement location||
||grts_address|int|GRTS address (`final`, i.e. after prior replacements)||
||type|varchar|type (code), our latest best assessment||
||grts_address_replacement|int|GRTS address (`final`, i.e. after corrections)||
||replacement_rank|smallint|replacement preference order||
||date_visit|date|date of visit of this location||
||teammember_id|smallint|link to the colleague who performed the visit||
||replacement_reason|text|explanation for replacement choice, e.g. inaccessibility||
||replacement_permanence|text|whether or not the location is permanently unavailable||
||is_inappropriate|boolean|indicating whether this location was visited but inappropriate as replacement unit||
||is_selected|boolean|indicating whether this location was selected as replacement unit||
||implications_habitatmap|boolean|whether disapproval has implications for habitat map||
||type_suggested|varchar|type suggested for a non-selected replacement cell||
||type_is_absent|boolean|unsuccessful local replacement / target type not found||
||notes|text|free text notes which will be transferred to the field app||

## Overview: MNM "SURF" Data Collection
as of [[timeline/2026-08-14|2026-08-14]]

|   |   |   |   |   |   |
|---|---|---|---|---|---|
|**_category_**|**_column_**|**_datatype_**|**_name_dutch_**|**_comment_**|**_note_**|
|**technisch/informatief**||||||
||log_user|varchar||(technical) user who modified the entry||
||log_update|timestamp(3)||(technical) timestamp of last modification||
||grts_address|bigint||GRTS address (`final`, i.e. after prior replacements) needed for retainer lookup||
||type|varchar||actually stratum for which the cell is eligible||
||activiteit = *DATACOLL|smallint||a link to the activity metadata, brought here via fieldcalendar for convenience|(always DATACOLL)|
||date_start|date||start of the panel activity sequence (included to keep recurrent visits unique)||
||landowner|varchar||reference to the land owner|_rough categories (ANB/natuurpunt/MIL/.../neither)_|
|||||||
|**algemeen**||||||
||teammember_id|smallint||link to the user who performed the visit||
||datetime_visit|timestamp(0)||date and time of the field activity||
||sampling_done|boolean||confirm that SamplingPoint was chosen, sampling has been performed, LIMS information captured||
||notes|text||Free text notes from the previous visits||
||issues|boolean||highlight issues (use notes to specify)||
||photo|varchar||mandatory photo of the sampling site at target location||
||accessibility_inaccessible|boolean||tag inaccessible locations|_synced with other databases_|
||accessibility_revisit|date||anticipate accessibility change|_synced with other databases_|
||recovery_hints|varchar||notes on how to find back the marking|_synced with other databases_|
||equipment_recommendations|text||required equipment and clothing to reach the target destination|_synced with other databases_|
||on_private_property|boolean||flag locations on private ground|_synced with other databases_|
||visit_done|boolean||filter column for locations which have already been visited||
|||||||
|**staalname**||||||
||equipment|varchar|monstername apparatuur|(wadend, schepstok) - sampling equipment (wading, scoop stick)||
||chlorophytae_presence|boolean|aanwezigheid vegetatie/metaphyton/drijflaag|presence of vegetation, metaphyton and/or float at the sample point||
||chlorophytae_specification|varchar|specificatie phytae|specification of non-open water and expected effect on sample|conditional visibility|
||waterdepth_samplingpoint_cm|double precision|waterdiepte staalnamepunt (cm)|the current depth of the water body at the sampling point||
||secchi_depth_cm|double precision|Secchidiepte (cm)|the depth at which a monochrome radially patterned disc is visually perceivable, with the tools of Angelo Secchi (1865)||
||clear_to_bottom|boolean|bodem zichtbaar|all clear: whether Secchi depth equals water depth at sampling point||
||sludge_thickness|double precision|sliblaag dikte|sludge layer thickness in centimeters||
||waterlevel_elevation_mtaw|double precision|waterpeil (mTAW)|elevation of the water level (mTAW)|(measured with RTK-GPS)|
|||||||
|**staalchemie**||||||
||project_code|varchar|LIMS projectcode|LIMS project code of this sample||
||recipient_code|varchar|LIMS staalcode|LIMS recipient code of this sample||
||watertemperature_celsius|double precision|T (°C)|water temperature at the sampling spot||
||sample_ph|double precision|pH|-log10([H+])||
||electric_conductivity_mus_cm|double precision|EC (µS/cm)|electric conductivity measurement||
||dissolved_oxygen_mg_l|double precision|DO (mg/L)|oxygen measurement||
||dissolved_oxygen_percent|double precision|DO%|oxygen saturation in percent||
||sample_notes|text|extra opmerkingen|misc notes on hydrological parameters||
|||||||
|**staalbeschrijving**||||||
||sample_contamination|boolean|staal niet zuiver|(waar/onwaar) - whether the sample is contaminated, i.e. not free of dirt particles||
||sample_contamination_reason|varchar|reden onzuiverheid|reason / character of the sample contamination|conditional visibility|
||sneller_cm|double precision|Sneller|visibility depth of a small Secchi disc in a gray PVC tube filled with sample water||
||color|varchar|kleur|(geen, geel, oranje, bruin, zwart, groen, grijs, rood) - color of the water||
||smell|varchar|geur|(geen, metallisch, zwavel, ammoniak, mest, riool, visachtig) - specific, noteworthy smell of the water||
||zooplankton|varchar|zoöplankton|(geen, weinig, matig, veel) passively moving aquatic critter||
||macroinvertebrates|varchar|macroinvertebraten|(geen, weinig, matig, veel) more / arthropod critter||
||xphoto_sample|varchar||extra photo of the sample water in a bucket||
|||||||
|**poelbeschrijving**||||||
||_geometry_|||Point geometry (31370 / Lambert 72)|(optionally independent of GRTS location)|
||max_depth_cm|int|maximale diepte (cm)|estimated maximum depth of the pool (cm)||
||connectivity|varchar|connectiviteit|(gesloten, instroom, doorstroom, overstroomd) how this pool connects to other water bodies: isolated, inflow, throughflow, overflow||
||seep_influence|varchar|kwelinvloed|(niet, iriserende film, roestbruinig water of slib) seep/spring instream of groundwater||
||coverage_rate|int|niet-open wateroppervlak (bedekking %)|coverage / rate of non-open water, in percent||
||shading|int|beschaduwing (%)|percantage shading of the water surface (estimated, noon)||
||leaf_deposition|int|bladinval (%)|share of watersurface which is straight under tree branches to indicate influence of leaf deposition||
||organic_material|varchar|grof organisch materiaal|(weinig, matig, veel) rough estimate of organic input load||
||emergents|int|emergente vegetatie (bedekking %)|horizontal projection of ground-rooted plants which emerge from the water surface||
||float_pleustophytes|int|pleustofyten (bedekking %)|coverage rate with floating plants (e.g. Lemnoidae, Stratiotes); horizontal surface / percent||
||float_nymphaeids|int|nymphaeiden (bedekking %)|coverage rate with floating parts of rooted plants (Nymphaeaceae, e.g. Nymphaea, Nuphar); horizontal surface / percent||
||submers_coverage|int|submerse vegetatie (bedekking %)|coverage with submersive plants||
||submers_pvi|int|submerse vegetatie (PVI)|submersive plant infestation (vertical projection), in percent||
||metaphyton|int|metaphyton (bedekking %)|water column coverage rate (percentage) of metaphytic filamentous algae||
||meandering|varchar||meandering/micromeandering of a stream|only lotic types / tbd|
||flowvel|double precision||flow velocity measured in m/s|only lotic types / tbd|
||flowvel_method|varchar||flow velocity measurement method (e.g. the orange method™)|only lotic types / tbd|
||barriers|varchar||pump, valve, unnatural mouth, base, pit, siphon, diver|only lotic types / tbd|
||current_pits|varchar||current pit presence/influence|only lotic types / tbd|
||notes|text||Free text notes from the previous visits||
||alert|boolean||emphasize this observation||
||photo|varchar||an optional photo of the site or noteworthy thing||
|||||||
|**verstoringen**||||||
||_geometry_|||Point geometry (31370 / Lambert 72)|(optionally independent of GRTS location)|
||other_perturbations|varchar|andere verstoring|other perturbation not listed below (specify)||
||cow_pats|boolean|koeienvlaaien|(aanwezig/niet) cow droppings, fresh or dry|Yes, we really do have a field for "koeienvlaaien".|
||other_animal_manure|boolean|andere dierlijke mest|(aanwezig/niet) animal feces in noteworthy amounts||
||grazers|boolean|grazers|(aanwezig/niet) noted the presence of grazers, then those are obviously no ninja grazers||
||trampling|boolean|trampling|(aanwezig/niet) trampling, can be an indication of grazers, or fat German tourists||
||intense_livestock_farming|boolean|(Intensieve) veehouderij in de buurt|(waar/onwaar) just what it says...||
||agriculture_nearby|boolean|akkers in de buurt|(waar/onwaar) proximity of agricultural fields||
||recent_fertilization_nearby|boolean|recente bemesting in de buurt|(waar/onwaar) indication of recent fertilization||
||busy_roads_nearby|boolean|drukke verkeerswegen in de buurt|(waar/onwaar) potential influence of emissions from the transport sector||
||industry_nearby|boolean|industrie in de buurt|(waar/onwaar) industrial sites which might affect the nitrogen situation||
||fish|boolean|vis|(waar/onwaar) I suppose the MV referred to Osteichthyes||
||birds|boolean|vogels|(waar/onwaar) the avian subclade of theropod dinosaurs||
||bird_droppings|boolean|vogeluitwerpselen|(waar/onwaar) bird shit||
||beaver|boolean|bever|(waar/onwaar) any traces of the beaver: bite marks, dams and lodges, or the animal itself||
||invasive_species|boolean|invasieve soorten|(waar/onwaar) e.g. Impatiens glandilufera, Elodea canadensis, Lemna minuta, Hydrocotyle ranunculoides, Fallopia japonica, Heracleum mantegazzianum||
||bank_reinforcement|boolean|oeverversteviging|(waar/onwaar) anthropogenic support of erosive shorelines||
||drainage_structures|boolean|drainagestructuren (buizen, grachten)|(waar/onwaar) tubes, ditches, canals, pits||
||fencing|boolean|prikkel- of schrikdraad|(waar/onwaar) barbed or electric wire||
||notes|text||Free text notes from the previous visits||
||alert|boolean||emphasize this observation||
||photo|varchar||an optional photo of the site or noteworthy thing||
|||||||
|**meteorologie**||||||
||_geometry_|||Point geometry (31370 / Lambert 72)|(optionally independent of GRTS location)|
||prior_48h|varchar|weer afgelopen 48 uur|whether or not there was rain in the previous 48 hours||
||exceptional|varchar|uitzonderlijke/extreme weersomstandigheden|period of exceptional weather phenomena (heat, drought, storms...)||
||precipitation|boolean|neerslag op moment van staalname (true/false)|(waar/onwaar) precipitation / moment of sampling||
||precipitation_specify|varchar|soort neerslag|(regen, hagel, sneeuw) specify: rain, hail, snow, honden/katten/cavia|conditional visibility|
||precipitation_intensity|varchar|intensiteit neerslag|(licht, matig, zwaar) specify: low, mid, high intensity of precip|conditional visibility|
||overcast|varchar|actuele bewolking|(zonnig, licht, zwaar, betrokken, mistig) type overcast (sun, clouds, mist, animal-shaped clouds)||
||airtemperature_celsius|double precision|luchttemperatuur (°C)|measurement via phone, (car) thermometer, or KMI reference||
||wind|varchar|actuele windcondities|(geen, zwak, matig, sterk) wind conditions: weak, moderate, strong||
||ice_layer_cm|double precision|ijslaag (cm)|ice layer thickness (if present)||
||notes|text||Free text notes from the previous visits||
||alert|boolean||emphasize this observation||
||photo|varchar||an optional photo of the site or noteworthy thing||
|||||||
|**chlorophyll**|||||**Temporary experiment**|
||grts_address|bigint||GRTS address (`final`, i.e. after prior replacements) needed for retainer lookup|_locations manually selected by NDT_|
||type|varchar||strata (optional/informative)||
||iteration|int||counting chlorophyll capturings||
||pool_in_rep|boolean||whether the pool is part of the REP sample||
||date_first_visit|date||start of the panel activity sequence (included to keep recurrent visits unique)||
||infos|text||infos about the target location||
||teammember_id|smallint||link to the user who performed the visit||
||datetime_visit|timestamp(0)||date and time of the field activity||
||notes|text||Free text notes from the previous visits||
||issues|boolean||highlight issues (use notes to specify)||
||photo|varchar||mandatory photo of the sampling site at target location||
||watertemperature_celsius|double precision||water temperature at the sampling spot||
||torch_a_freewater_1|double precision||(repeated measurements)||
||torch_a_freewater_2|double precision||(repeated measurements)||
||torch_a_freewater_3|double precision||(repeated measurements)||
||torch_a_sample_1|double precision||(repeated measurements)||
||torch_a_sample_2|double precision||(repeated measurements)||
||torch_a_sample_3|double precision||(repeated measurements)||
||torch_b_sample_1|double precision||(repeated measurements)||
||torch_b_sample_2|double precision||(repeated measurements)||
||torch_b_sample_3|double precision||(repeated measurements)||
||fluo_a_sample_1|double precision||(repeated measurements)||
||fluo_a_sample_2|double precision||(repeated measurements)||
||fluo_a_sample_3|double precision||(repeated measurements)||
||fluo_b_sample_1|double precision||(repeated measurements)||
||fluo_b_sample_2|double precision||(repeated measurements)||
||fluo_b_sample_3|double precision||(repeated measurements)||
||samplingpoint_marked|boolean||check that the sampling point was marked on the map|reminder to set a new SamplingPoint|
||visit_done|boolean||filter column for locations which have already been visited||
|||||||
|**staalnamepunt**||||||
||**geometry**|||Point geometry (31370 / Lambert 72): sampling location||
||date_sampling|date||the date of sampling point selection (preference for the newest)||
||purpose_chlorophyll|boolean||flag sample points marked for chlorophyll measurements||
||photo|varchar||optional photo of the sampling location to illustrate irregularities||
||notes|text||extra notes about the sampling point||