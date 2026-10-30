ALTER TABLE device.device
    ADD COLUMN IF NOT EXISTS measurement_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS measurement_updated_at TIMESTAMPTZ;

COMMENT ON COLUMN device.device.measurement_enabled IS
    'Last measurement state confirmed by the physical IoT device.';

COMMENT ON COLUMN device.device.measurement_updated_at IS
    'Timestamp of the latest accepted measurement-state confirmation from the device.';
