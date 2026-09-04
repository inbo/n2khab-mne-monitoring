

new SampleLocations info:
    is_forest
    in_mhq_samples

mhq assessment to SampleLocations: shortcut; should later be made dynamic (via LocationEvaluations)
    has_mhq_assessment = last_type_assessment_in_field,
    mhq_assessment_date = last_type_assessment

new fwcal flags:
    wait_any
    wait_floating



ALTER TABLE "outbound"."SampleLocations" ADD COLUMN is_forest bool NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN "outbound"."SampleLocations".is_forest IS E'flag forest type sample locatione';

ALTER TABLE "outbound"."SampleLocations" ADD COLUMN in_mhq_samples bool NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN "outbound"."SampleLocations".in_mhq_samples IS E'flag sites used for MHQ';

ALTER TABLE "outbound"."SampleLocations" ADD COLUMN has_mhq_assessment bool NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN "outbound"."SampleLocations".has_mhq_assessment IS E'(temporary) column to filter MHQ polygons';



ALTER TABLE "outbound"."FieldworkCalendar" ADD COLUMN wait_any boolean;
COMMENT ON COLUMN "outbound"."FieldworkCalendar".wait_any IS E'must I always be waiting, waiting on you? *whistle*';

ALTER TABLE "outbound"."FieldworkCalendar" ADD COLUMN wait_floating boolean;
COMMENT ON COLUMN "outbound"."FieldworkCalendar".wait_floating IS E'filter field for convenient floating type (de)selection';


-- !!! adjusted way of getting SampleUnits



-- TODO: inaccessibility info

fag_stratum_grts_calendar %>%
  count(inaccessible)
