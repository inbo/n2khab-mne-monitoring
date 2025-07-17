

-- persistent -> give extra locations
-- parallel to LocationAssessments
-- adjust views AND split update rules

-- also MOVE landowner


-- ++ update rules
DROP TRIGGER IF EXISTS log_locationinfos ON "inbound"."LocationInfos";
CREATE TRIGGER log_locationinfos
BEFORE UPDATE ON "inbound"."LocationInfos"
FOR EACH ROW EXECUTE PROCEDURE sync_mod();
