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

-- on loceval
DROP TRIGGER IF EXISTS log_assessments ON "outbound"."LocationAssessments";
CREATE TRIGGER log_assessments
BEFORE UPDATE ON "outbound"."LocationAssessments"
FOR EACH ROW EXECUTE PROCEDURE sync_mod();

DROP TRIGGER IF EXISTS log_fieldactivitycalendar ON "outbound"."FieldActivityCalendar";
CREATE TRIGGER log_fieldactivitycalendar
BEFORE UPDATE ON "outbound"."FieldActivityCalendar"
FOR EACH ROW EXECUTE PROCEDURE sync_mod();

DROP TRIGGER IF EXISTS log_freefieldnotes ON "inbound"."FreeFieldNotes";
CREATE TRIGGER log_freefieldnotes
BEFORE UPDATE ON "inbound"."FreeFieldNotes"
FOR EACH ROW EXECUTE PROCEDURE sync_mod();

DROP TRIGGER IF EXISTS log_visits ON "inbound"."Visits";
CREATE TRIGGER log_visits
BEFORE UPDATE ON "inbound"."Visits"
FOR EACH ROW EXECUTE PROCEDURE sync_mod();

DROP TRIGGER IF EXISTS log_cellmaps ON "inbound"."CellMaps";
CREATE TRIGGER log_cellmaps
BEFORE UPDATE ON "inbound"."CellMaps"
FOR EACH ROW EXECUTE PROCEDURE sync_mod();


-- on mnmfield
DROP TRIGGER IF EXISTS log_fieldactivitycalendar ON "outbound"."FieldActivityCalendar";
CREATE TRIGGER log_fieldactivitycalendar
BEFORE UPDATE ON "outbound"."FieldActivityCalendar"
FOR EACH ROW EXECUTE PROCEDURE sync_mod();

DROP TRIGGER IF EXISTS log_localreplacements ON "inbound"."LocalReplacements";
CREATE TRIGGER log_localreplacements
BEFORE UPDATE ON "inbound"."LocalReplacements"
FOR EACH ROW EXECUTE PROCEDURE sync_mod();

DROP TRIGGER IF EXISTS log_visits ON "inbound"."Visits";
CREATE TRIGGER log_visits
BEFORE UPDATE ON "inbound"."Visits"
FOR EACH ROW EXECUTE PROCEDURE sync_mod();

DROP TRIGGER IF EXISTS log_freefieldnotes ON "inbound"."FreeFieldNotes";
CREATE TRIGGER log_freefieldnotes
BEFORE UPDATE ON "inbound"."FreeFieldNotes"
FOR EACH ROW EXECUTE PROCEDURE sync_mod();
