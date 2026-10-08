REVOKE ALL ON FUNCTION device.fn_link_device_to_home_by_hardware(VARCHAR, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION device.fn_link_device_to_home_by_hardware(VARCHAR, UUID) TO hidro_smart_app;
