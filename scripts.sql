-- add columns
ALTER TABLE transactions add column modified_by TEXT;
ALTER TABLE transactions add column modified_at TIMESTAMP;

-- capture before records on debezium
ALTER TABLE transactions REPLICA IDENTITY FULL;


-- capture the changes to specific columns into json object
CREATE OR REPLACE FUNCTION record_changed_columns()
RETURNS TRIGGER AS $$
DECLARE
    change_details JSONB;
BEGIN
    change_details := '{}'::JSONB; -- Initialize an empty JSONB object

    -- Check each column for changes and record as necessary
    IF NEW.amount IS DISTINCT FROM OLD.amount THEN
        change_details := jsonb_insert(change_details, '{amount}', jsonb_build_object('old', OLD.amount, 'new', NEW.amount));
    END IF;

    -- Add user and timestamp
    NEW.modified_by := current_user;
    NEW.modified_at := CURRENT_TIMESTAMP;

    -- Update the change_info column
    NEW.change_info := change_details;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--change information column
ALTER TABLE transactions ADD COLUMN change_info JSONB;

-- Trigger for UPDATE
CREATE TRIGGER trigger_record_user_update
BEFORE UPDATE ON transactions
FOR EACH ROW EXECUTE FUNCTION record_changed_columns();

