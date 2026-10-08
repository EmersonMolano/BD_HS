REVOKE ALL ON FUNCTION home.fn_create_home_with_billing_profile(VARCHAR, VARCHAR, VARCHAR, SMALLINT, UUID, VARCHAR, INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION home.fn_sync_home_reference_rate(UUID) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION home.fn_create_home_with_billing_profile(VARCHAR, VARCHAR, VARCHAR, SMALLINT, UUID, VARCHAR, INTEGER) TO hidro_smart_app;
GRANT EXECUTE ON FUNCTION home.fn_sync_home_reference_rate(UUID) TO hidro_smart_app;
GRANT SELECT ON alert_rate.reference_rate TO hidro_smart_app;
