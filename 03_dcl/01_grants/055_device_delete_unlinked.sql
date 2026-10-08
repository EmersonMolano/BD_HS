REVOKE ALL ON FUNCTION device.fn_delete_unlinked_device(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION device.fn_delete_unlinked_device(UUID) TO hidro_smart_app;
