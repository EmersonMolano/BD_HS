-- Codigos logicos reservados para placas ESP32 de HidroSmart.
-- No son hardwareId: el eFuse fisico se reclama por BLE/MQTT al primer uso.
-- Los registros nacen sin hogar para que un Owner los vincule desde la interfaz.
INSERT INTO device.device (
    code,
    name,
    type,
    status,
    provisioning_status
)
VALUES
    ('HS-7A3F91C8D2E4', 'ESP32 HidroSmart 01', 'water_sensor', 'Active', 'PENDING'),
    ('HS-B6E04D79A153', 'ESP32 HidroSmart 02', 'water_sensor', 'Active', 'PENDING'),
    ('HS-2C8A5F01E7B9', 'ESP32 HidroSmart 03', 'water_sensor', 'Active', 'PENDING')
ON CONFLICT (code) DO NOTHING;
