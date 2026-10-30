REVOKE ALL ON FUNCTION device.fn_record_device_measurement_state(VARCHAR, BOOLEAN, TIMESTAMPTZ) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION device.fn_record_device_measurement_state(VARCHAR, BOOLEAN, TIMESTAMPTZ) TO hidro_smart_app;
