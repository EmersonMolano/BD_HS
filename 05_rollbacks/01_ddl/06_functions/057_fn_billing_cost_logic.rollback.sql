CREATE OR REPLACE FUNCTION consumption.fn_calculate_cost(
    p_consumption_m3 DECIMAL,
    p_home_id UUID,
    p_date DATE
)
RETURNS DECIMAL(12,2)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = consumption, alert_rate, home, public, pg_temp
AS $$
DECLARE
    v_rate DECIMAL(12,4);
    v_home_tier SMALLINT;
BEGIN
    SELECT h.tier INTO v_home_tier FROM home.home h WHERE h.home_id = p_home_id;

    SELECT hr.m3_value
      INTO v_rate
      FROM alert_rate.home_rate hr
     WHERE hr.home_id = p_home_id
       AND hr.tier = v_home_tier
       AND hr.valid_from <= p_date
       AND (hr.valid_until IS NULL OR hr.valid_until >= p_date)
     ORDER BY hr.valid_from DESC
     LIMIT 1;

    IF v_rate IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN ROUND(p_consumption_m3 * v_rate, 2);
END;
$$;

CREATE OR REPLACE FUNCTION consumption.fn_calculate_period_cost(
    p_home_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS DECIMAL(12,2)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = consumption, alert_rate, home, public, pg_temp
AS $$
DECLARE
    v_variable_cost DECIMAL(14,2);
    v_fixed_charge DECIMAL(12,2);
    v_unpriced_readings INTEGER;
BEGIN
    IF p_start_date IS NULL OR p_end_date IS NULL OR p_end_date < p_start_date THEN
        RAISE EXCEPTION 'El rango de fechas del periodo no es válido';
    END IF;

    SELECT COALESCE(SUM(sr.consumption_m3 * hr.m3_value), 0)::DECIMAL(14,2),
           COUNT(*) FILTER (WHERE hr.rate_id IS NULL)::INTEGER
      INTO v_variable_cost, v_unpriced_readings
      FROM consumption.sensor_reading sr
      JOIN home.home h ON h.home_id = sr.home_id
      LEFT JOIN LATERAL (
          SELECT r.rate_id, r.m3_value
            FROM alert_rate.home_rate r
           WHERE r.home_id = sr.home_id
             AND r.tier = h.tier
             AND r.valid_from <= sr.recorded_at::DATE
             AND (r.valid_until IS NULL OR r.valid_until >= sr.recorded_at::DATE)
           ORDER BY r.valid_from DESC
           LIMIT 1
      ) hr ON TRUE
     WHERE sr.home_id = p_home_id
       AND sr.recorded_at::DATE BETWEEN p_start_date AND p_end_date;

    IF v_unpriced_readings > 0 THEN
        RETURN NULL;
    END IF;

    SELECT r.fixed_charge
      INTO v_fixed_charge
      FROM alert_rate.home_rate r
      JOIN home.home h ON h.home_id = p_home_id
     WHERE r.home_id = p_home_id
       AND r.tier = h.tier
       AND r.valid_from <= p_start_date
       AND (r.valid_until IS NULL OR r.valid_until >= p_start_date)
     ORDER BY r.valid_from DESC
     LIMIT 1;

    IF v_fixed_charge IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN ROUND(v_variable_cost + v_fixed_charge, 2);
END;
$$;

DROP FUNCTION IF EXISTS alert_rate.fn_home_basic_limit_m3(UUID);
