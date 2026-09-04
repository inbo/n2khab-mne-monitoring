ALTER TABLE "outbound"."LocationInfos" ADD COLUMN watina_code_1 varchar;
COMMENT ON COLUMN "outbound"."LocationInfos".watina_code_1 IS E'prepared and reserved WATINA code for obs well placement (1)';

ALTER TABLE "outbound"."LocationInfos" ADD COLUMN watina_code_2 varchar;
COMMENT ON COLUMN "outbound"."LocationInfos".watina_code_2 IS E'prepared and reserved WATINA code for obs well placement (2)';


-- adjust gw_FieldworkPlanning.sql view

-- re-init db
-- move data - there was none

ALTER TABLE "outbound"."FieldworkCalendar" DROP COLUMN watina_code;
