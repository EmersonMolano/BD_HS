DROP INDEX IF EXISTS alert_rate.uq_reference_rate_category_valid_from;
DROP TABLE IF EXISTS alert_rate.reference_rate;

ALTER TABLE alert_rate.home_rate
    DROP CONSTRAINT IF EXISTS ck_home_rate_usage_type_tier;

ALTER TABLE alert_rate.home_rate
    DROP COLUMN IF EXISTS unit_billing,
    DROP COLUMN IF EXISTS unit_sensor,
    DROP COLUMN IF EXISTS rate_source,
    DROP COLUMN IF EXISTS reference_consumption_m3,
    DROP COLUMN IF EXISTS excess_m3_value,
    DROP COLUMN IF EXISTS basic_m3_value,
    DROP COLUMN IF EXISTS usage_type;

ALTER TABLE alert_rate.home_rate
    ALTER COLUMN tier SET NOT NULL;

ALTER TABLE home.home
    DROP CONSTRAINT IF EXISTS ck_home_usage_type_tier,
    DROP CONSTRAINT IF EXISTS ck_home_altitude_meters,
    DROP CONSTRAINT IF EXISTS ck_home_usage_type,
    DROP COLUMN IF EXISTS altitude_meters,
    DROP COLUMN IF EXISTS usage_type;
