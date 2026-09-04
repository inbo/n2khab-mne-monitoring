Location 871030 hosts two types (4010 & 7150)
--> was originally 84598 and got replaced (both types same cell pre&post)

observation:

SELECT *
FROM "outbound"."FieldworkCalendar"
WHERE samplelocation_id IN (857, 858)
  AND activity_group_id = 4;
 fieldworkcalendar_id |  log_user   |         log_update         | samplelocation_id | grts_address | sspstapa_id | date_start |  date_end  | activity_group_id | activity_rank | priority | done_planning
----------------------+-------------+----------------------------+-------------------+--------------+-------------+------------+------------+-------------------+---------------+----------+---------------
                 1161 | falk        | 2025-08-23 07:59:56.976898 |               858 |       871030 |             | 2025-10-01 | 2025-12-31 |                 4 |             2 |        2 | f
                 1201 | maintenance | 2025-08-23 07:59:46.845211 |               857 |       871030 |         212 | 2025-10-01 | 2025-12-31 |                 4 |             2 |        2 | f
(2 rows)

[there are four activity_group_id`s in total: 4, 11, 13, 28]


SELECT * FROM "outbound"."SampleLocations" WHERE samplelocation_id IN (857, 858);
SELECT * FROM "outbound"."SampleLocations" WHERE grts_address = 871030;

 samplelocation_id | location_id | grts_address |         scheme_ps_targetpanels          | schemes | strata | is_replacement
-------------------+-------------+--------------+-----------------------------------------+---------+--------+----------------
               857 |         698 |       871030 | GW_03.3:PS1PANEL08 | GW_03.3:PS1PANEL10 | GW_03.3 | 4010   | f
               858 |         698 |       871030 | GW_03.3:PS1PANEL08 | GW_03.3:PS1PANEL10 | GW_03.3 | 7150   | f


### HOWEVER, note
    that only 7150 has gw-activities planned so far:

fieldwork_2025_prioritization_by_stratum %>%
  filter(grts_address == 84598, field_activity_group == "GWINSTPIEZWELL") %>%
  t() %>% knitr::kable()

|:----------------------|:-------------------------------|
|scheme_ps_targetpanels |GW_03.3:PS1PANEL08              |
|stratum                |7150                            |
|grts_address           |84598                           |
|grts_address_final     |84598                           |
|date_start             |2025-10-01                      |
|date_end               |2025-12-31                      |
|field_activity_group   |GWINSTPIEZWELL                  |
|rank                   |2                               |
|grts_join_method       |cell                            |
|priority               |2                               |
|wait_watersurface      |FALSE                           |
|wait_3260              |FALSE                           |
|wait_7220              |FALSE                           |

This means that no calendar entries should appear for 4010; keeping this in mind.


No visits have been executed yet.
prior_visits %>% filter(fieldworkcalendar_id %in% c(1161, 1201))


Problem: the fieldwork_calendar already associates wrong SampleLocation
fieldwork_calendar %>% filter(grts_address == 871030, activity_group_id == 4) %>% t() %>% knitr::kable()


Upstream: the replacements both get associated with 857:
replacements %>% filter(grts_address_replacement == 871030) %>% t() %>% knitr::kable()

SELECT * FROM "archive"."ReplacementData" WHERE grts_address = 84598;
| type | grts_address | grts_address_replacement | new_samplelocation_id |
|------+--------------+--------------------------+-----------------------|
| 4010 |        84598 |                   871030 |                   857 |
| 7150 |        84598 |                   871030 |                   857 |
(2 rows)


--> briefly switching back to 092 // Python

[!] the samplelocation_id join is stratum-agnostic. (which *was* okay until we had this new case.)
SELECT DISTINCT
  grts_address,
  -- strata,
  samplelocation_id,
  location_id AS location_id_current
FROM "outbound"."SampleLocations"
WHERE grts_address = 871030;

Good. Let`s include stratum.

--> done. Testing, adjusting further downstream, reporting back if failed.


NO! Not there yet!
the activities are still associated with 857.

MANUAL intervention:
SELECT * FROM "archive"."ReplacementData" WHERE grts_address = 84598;
UPDATE "archive"."ReplacementData" SET new_samplelocation_id = 858 WHERE replacementdata_id = 554;

re-ran 092 both mirrors -> seems good.

re-ran 093 staging -> seems good.


There is still the obsolete activity on 4010; why is it not covered as "obsolete"?


SELECT *
FROM "outbound"."FieldworkCalendar" AS CAL
LEFT JOIN "outbound"."SampleLocations" AS SLOC
  ON SLOC.samplelocation_id = CAL.samplelocation_id
WHERE TRUE
  AND CAL.grts_address IN (84598, 871030)
  AND activity_group_id = 4
;


And indeed, those are identified and auto-removed by the following:
delete_obsolete_calendar_entries(obsolete_nonplans)
