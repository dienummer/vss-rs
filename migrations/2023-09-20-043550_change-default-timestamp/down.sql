ALTER TABLE vss_db
    ALTER COLUMN created_date SET DEFAULT CURRENT_TIMESTAMP,
    ALTER COLUMN updated_date SET DEFAULT CURRENT_TIMESTAMP;
