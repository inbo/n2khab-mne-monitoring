





-- https://stackoverflow.com/a/1491329


WITH current_team (username) AS (
  SELECT DISTINCT LOWER(username) FROM "metadata"."TeamMembers"
  WHERE username NOT LIKE 'all_%'
)
SELECT (COUNT(*) > 0) AS is_editor
FROM current_user, current_team
WHERE current_user = username
;



DROP FUNCTION IF EXISTS "metadata".sync_mod CASCADE;

CREATE OR REPLACE FUNCTION "metadata".sync_mod()
RETURNS trigger AS
$sync_mod$
DECLARE is_teammember BOOLEAN;
BEGIN

  SELECT current_user IN (
    SELECT DISTINCT LOWER(username) FROM "metadata"."TeamMembers"
    WHERE username NOT LIKE 'all_%'
  )
  INTO is_teammember
  ;

  IF is_teammember THEN
    NEW.log_update := current_timestamp(3);
    NEW.log_user := current_user;
  END IF;

  RETURN NEW
  ;
END;
$sync_mod$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS log_freefieldnotes ON "inbound"."FreeFieldNotes";
CREATE TRIGGER log_freefieldnotes
BEFORE UPDATE ON "inbound"."FreeFieldNotes"
FOR EACH ROW EXECUTE PROCEDURE "metadata".sync_mod();


INSERT INTO "metadata"."TeamMembers"
(username) VALUES ('tester'), ('monkey');


INSERT INTO "metadata"."TeamMembers"
(username) VALUES ('falk');


DELETE FROM "metadata"."TeamMembers"
WHERE username = 'falk';

SELECT * FROM "inbound"."FreeFieldNotes";
UPDATE "inbound"."FreeFieldNotes" SET log_user = 'maintenance';

