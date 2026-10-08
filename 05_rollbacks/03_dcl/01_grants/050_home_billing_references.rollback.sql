REVOKE EXECUTE ON FUNCTION home.fn_create_home_with_billing_profile(VARCHAR, VARCHAR, VARCHAR, SMALLINT, UUID, VARCHAR, INTEGER) FROM hidro_smart_app;
REVOKE EXECUTE ON FUNCTION home.fn_sync_home_reference_rate(UUID) FROM hidro_smart_app;
REVOKE SELECT ON alert_rate.reference_rate FROM hidro_smart_app;
