-- https://stackoverflow.com/a/8745713



DROP FUNCTION IF EXISTS sync_mod CASCADE;
CREATE FUNCTION sync_mod() RETURNS trigger AS $sync_mod$
BEGIN
  NEW.log_update := current_timestamp;
  NEW.log_user := current_user;
  -- NEW.log_user := CASE WHEN current_user = 'yoda' THEN OLD.log_user ELSE current_user END;

  RETURN NEW
  ;
END;
$sync_mod$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS log_assessments ON "outbound"."LocationAssessments";
CREATE TRIGGER log_assessments
BEFORE UPDATE ON "outbound"."LocationAssessments"
FOR EACH ROW EXECUTE PROCEDURE sync_mod();

DROP TRIGGER IF EXISTS log_freefieldnotes ON "inbound"."FreeFieldNotes";
CREATE TRIGGER log_freefieldnotes
BEFORE UPDATE ON "inbound"."FreeFieldNotes"
FOR EACH ROW EXECUTE PROCEDURE sync_mod();
