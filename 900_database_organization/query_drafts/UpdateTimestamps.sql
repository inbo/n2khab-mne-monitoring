-- https://stackoverflow.com/a/8745713


DROP FUNCTION IF EXISTS sync_mod CASCADE;
CREATE FUNCTION sync_mod() RETURNS trigger AS $sync_mod$
BEGIN
    NEW.log_update := current_timestamp;
    NEW.log_user := current_user;

    RETURN NEW;
END;
$sync_mod$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS log_locationcalendar ON "outbound"."LocationCalendar";
CREATE TRIGGER log_locationcalendar
BEFORE UPDATE ON "outbound"."LocationCalendar"
FOR EACH ROW EXECUTE PROCEDURE sync_mod();

DROP TRIGGER IF EXISTS log_visits ON "inbound"."Visits";
CREATE TRIGGER log_visits
BEFORE UPDATE ON "inbound"."Visits"
FOR EACH ROW EXECUTE PROCEDURE sync_mod();

DROP TRIGGER IF EXISTS log_freefieldnotes ON "inbound"."FreeFieldNotes";
CREATE TRIGGER log_freefieldnotes
BEFORE UPDATE ON "inbound"."FreeFieldNotes"
FOR EACH ROW EXECUTE PROCEDURE sync_mod();
