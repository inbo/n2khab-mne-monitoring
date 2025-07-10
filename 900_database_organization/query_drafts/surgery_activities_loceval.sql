-- ALTER TABLE "metadata"."GroupedActivities" ADD COLUMN is_loceval_activity boolean;


UPDATE "metadata"."GroupedActivities"
  SET is_loceval_activity = FALSE;


SELECT * FROM "metadata"."GroupedActivities"
WHERE activity = ANY(
'{LOCEVALAQ,LOCEVALAQ,LOCEVALAQ,LOCEVALTERR,LSVIAQ,LSVITERR,SURFLENTSAMPLPOINT,SURFLOTSAMPLPOINT}'::varchar[]
)
;



UPDATE "metadata"."GroupedActivities"
  SET is_loceval_activity = TRUE
WHERE activity = ANY(
'{LOCEVALAQ,LOCEVALAQ,LOCEVALAQ,LOCEVALTERR,LSVIAQ,LSVITERR,SURFLENTSAMPLPOINT,SURFLOTSAMPLPOINT}'::varchar[]
)
;
