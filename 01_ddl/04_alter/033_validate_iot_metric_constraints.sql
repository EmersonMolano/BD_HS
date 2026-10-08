-- Valida las restricciones de métricas que se agregaron como NOT VALID
-- durante el endurecimiento de la ingesta MQTT.
-- La validación se ejecuta después de comprobar que no existan filas inválidas.

ALTER TABLE consumption.sensor_reading
    VALIDATE CONSTRAINT ck_sensor_reading_battery_level;
ALTER TABLE consumption.sensor_reading
    VALIDATE CONSTRAINT ck_sensor_reading_flow_rate;
ALTER TABLE consumption.sensor_reading
    VALIDATE CONSTRAINT ck_sensor_reading_pulses;
ALTER TABLE consumption.sensor_reading
    VALIDATE CONSTRAINT ck_sensor_reading_sample_interval;
ALTER TABLE consumption.sensor_reading
    VALIDATE CONSTRAINT ck_sensor_reading_signal_quality;
ALTER TABLE consumption.sensor_reading
    VALIDATE CONSTRAINT ck_sensor_reading_temperature;
ALTER TABLE consumption.sensor_reading
    VALIDATE CONSTRAINT ck_sensor_reading_total_liters;
ALTER TABLE consumption.sensor_reading
    VALIDATE CONSTRAINT ck_sensor_reading_voltage;
ALTER TABLE consumption.sensor_reading
    VALIDATE CONSTRAINT ck_sensor_reading_wifi_rssi;

ALTER TABLE device.device
    VALIDATE CONSTRAINT ck_device_temperature_physical;
ALTER TABLE device.device
    VALIDATE CONSTRAINT ck_device_voltage_physical;
ALTER TABLE device.device
    VALIDATE CONSTRAINT ck_device_wifi_rssi_dbm;

ALTER TABLE device.device_telemetry_history
    VALIDATE CONSTRAINT ck_device_telemetry_temperature_physical;
ALTER TABLE device.device_telemetry_history
    VALIDATE CONSTRAINT ck_device_telemetry_voltage_physical;
ALTER TABLE device.device_telemetry_history
    VALIDATE CONSTRAINT ck_device_telemetry_wifi_rssi_dbm;
