CREATE TABLE vss_db
(
    store_id     TEXT                                NOT NULL CHECK (store_id != ''),
    key          TEXT                                NOT NULL,
    value        bytea,
    version      BIGINT                              NOT NULL,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (store_id, key)
);

-- triggers to set dates automatically, generated by ChatGPT

-- Function to set created_date and updated_date during INSERT
CREATE OR REPLACE FUNCTION set_created_date()
    RETURNS TRIGGER AS
$$
BEGIN
    NEW.created_date := CURRENT_TIMESTAMP;
    NEW.updated_date := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to set updated_date during UPDATE
CREATE OR REPLACE FUNCTION set_updated_date()
    RETURNS TRIGGER AS
$$
BEGIN
    NEW.updated_date := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for INSERT operation on vss_db
CREATE TRIGGER tr_set_dates_after_insert
    BEFORE INSERT
    ON vss_db
    FOR EACH ROW
EXECUTE FUNCTION set_created_date();

-- Trigger for UPDATE operation on vss_db
CREATE TRIGGER tr_set_dates_after_update
    BEFORE UPDATE
    ON vss_db
    FOR EACH ROW
EXECUTE FUNCTION set_updated_date();

CREATE OR REPLACE FUNCTION upsert_vss_db(
    p_store_id TEXT,
    p_key TEXT,
    p_value bytea,
    p_version BIGINT
) RETURNS VOID AS
$$
BEGIN

    WITH new_values (store_id, key, value, version) AS (VALUES (p_store_id, p_key, p_value, p_version))
    INSERT
    INTO vss_db
        (store_id, key, value, version)
    SELECT new_values.store_id,
           new_values.key,
           new_values.value,
           new_values.version
    FROM new_values
             LEFT JOIN vss_db AS existing
                       ON new_values.store_id = existing.store_id
                           AND new_values.key = existing.key
    WHERE CASE
              WHEN new_values.version >= 4294967295 THEN new_values.version >= COALESCE(existing.version, -1)
              ELSE new_values.version > COALESCE(existing.version, -1)
              END
    ON CONFLICT (store_id, key)
        DO UPDATE SET value   = excluded.value,
                      version = excluded.version;

END;
$$ LANGUAGE plpgsql;
