ALTER TABLE device.device
    DROP COLUMN IF EXISTS measurement_updated_at,
    DROP COLUMN IF EXISTS measurement_enabled;
