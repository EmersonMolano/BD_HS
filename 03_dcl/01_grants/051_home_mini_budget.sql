REVOKE ALL ON FUNCTION home.fn_create_home_with_billing_profile(VARCHAR, VARCHAR, VARCHAR, SMALLINT, UUID, VARCHAR, INTEGER, SMALLINT) FROM PUBLIC;
REVOKE ALL ON FUNCTION analytics_support.fn_get_home_budget_status(UUID, DATE) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION home.fn_create_home_with_billing_profile(VARCHAR, VARCHAR, VARCHAR, SMALLINT, UUID, VARCHAR, INTEGER, SMALLINT) TO hidro_smart_app;
GRANT EXECUTE ON FUNCTION analytics_support.fn_get_home_budget_status(UUID, DATE) TO hidro_smart_app;
