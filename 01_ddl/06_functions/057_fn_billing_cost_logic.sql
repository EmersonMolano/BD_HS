-- Convierte las lecturas del sensor (litros) a m³ y aplica la tarifa del
-- hogar. En residencial subsidiado, el valor básico solo aplica al consumo
-- básico; el excedente usa la tarifa de referencia.

CREATE OR REPLACE FUNCTION alert_rate.fn_home_basic_limit_m3(p_home_id UUID)
RETURNS DECIMAL(10,2)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = home, public, pg_temp
AS $$
    SELECT CASE
        WHEN h.altitude_meters IS NULL OR h.altitude_meters < 1000 THEN 16.00::DECIMAL(10,2)
        WHEN h.altitude_meters <= 2000 THEN 13.00::DECIMAL(10,2)
        ELSE 11.00::DECIMAL(10,2)
    END
      FROM home.home h
     WHERE h.home_id = p_home_id;
$$;

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
    v_usage_type VARCHAR(20);
    v_tier SMALLINT;
    v_basic_rate DECIMAL(12,4);
    v_excess_rate DECIMAL(12,4);
    v_basic_limit DECIMAL(10,2);
BEGIN
    IF p_consumption_m3 IS NULL THEN
        RETURN NULL;
    END IF;

    IF p_consumption_m3 < 0 THEN
        RAISE EXCEPTION 'El consumo no puede ser negativo';
    END IF;

    SELECT h.usage_type,
           h.tier,
           COALESCE(hr.basic_m3_value, rr.basic_m3_value),
           COALESCE(hr.excess_m3_value, rr.excess_m3_value)
      INTO v_usage_type, v_tier, v_basic_rate, v_excess_rate
      FROM home.home h
      LEFT JOIN LATERAL (
          SELECT r.basic_m3_value, r.excess_m3_value
            FROM alert_rate.home_rate r
           WHERE r.home_id = h.home_id
             AND r.valid_from <= p_date
             AND (r.valid_until IS NULL OR r.valid_until >= p_date)
           ORDER BY r.valid_from DESC
           LIMIT 1
      ) hr ON TRUE
      LEFT JOIN LATERAL (
          SELECT r.basic_m3_value, r.excess_m3_value
            FROM alert_rate.reference_rate r
           WHERE r.usage_type = h.usage_type
             AND r.tier IS NOT DISTINCT FROM h.tier
             AND r.active = TRUE
             AND r.valid_from <= p_date
             AND (r.valid_until IS NULL OR r.valid_until >= p_date)
           ORDER BY r.valid_from DESC
           LIMIT 1
      ) rr ON TRUE
     WHERE h.home_id = p_home_id;

    IF v_basic_rate IS NULL THEN
        RETURN NULL;
    END IF;

    IF v_usage_type = 'RESIDENTIAL' AND v_tier IN (1, 2, 3) THEN
        v_basic_limit := alert_rate.fn_home_basic_limit_m3(p_home_id);
        RETURN ROUND(
            LEAST(p_consumption_m3, v_basic_limit) * v_basic_rate
            + GREATEST(p_consumption_m3 - v_basic_limit, 0) * v_excess_rate,
            2
        );
    END IF;

    RETURN ROUND(p_consumption_m3 * v_basic_rate, 2);
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
    v_has_rate BOOLEAN;
BEGIN
    IF p_start_date IS NULL OR p_end_date IS NULL OR p_end_date < p_start_date THEN
        RAISE EXCEPTION 'El rango de fechas del periodo no es válido';
    END IF;

    SELECT EXISTS (
        SELECT 1
          FROM home.home h
          LEFT JOIN alert_rate.home_rate hr
            ON hr.home_id = h.home_id
           AND hr.valid_from <= p_start_date
           AND (hr.valid_until IS NULL OR hr.valid_until >= p_start_date)
          LEFT JOIN alert_rate.reference_rate rr
            ON rr.usage_type = h.usage_type
           AND rr.tier IS NOT DISTINCT FROM h.tier
           AND rr.active = TRUE
           AND rr.valid_from <= p_start_date
           AND (rr.valid_until IS NULL OR rr.valid_until >= p_start_date)
         WHERE h.home_id = p_home_id
           AND (hr.rate_id IS NOT NULL OR rr.reference_rate_id IS NOT NULL)
    ) INTO v_has_rate;

    IF NOT v_has_rate THEN
        RETURN NULL;
    END IF;

    SELECT COALESCE(SUM(calculated.cost), 0)::DECIMAL(14,2),
           COUNT(*) FILTER (WHERE calculated.cost IS NULL)::INTEGER
      INTO v_variable_cost, v_unpriced_readings
      FROM consumption.sensor_reading sr
      CROSS JOIN LATERAL (
          SELECT consumption.fn_calculate_cost(
              sr.consumption_m3,
              p_home_id,
              sr.recorded_at::DATE
          ) AS cost
      ) calculated
     WHERE sr.home_id = p_home_id
       AND sr.recorded_at::DATE BETWEEN p_start_date AND p_end_date;

    IF v_unpriced_readings > 0 THEN
        RETURN NULL;
    END IF;

    SELECT COALESCE(hr.fixed_charge, 0)
      INTO v_fixed_charge
      FROM alert_rate.home_rate hr
     WHERE hr.home_id = p_home_id
       AND hr.valid_from <= p_start_date
       AND (hr.valid_until IS NULL OR hr.valid_until >= p_start_date)
     ORDER BY hr.valid_from DESC
     LIMIT 1;

    RETURN ROUND(v_variable_cost + COALESCE(v_fixed_charge, 0), 2);
END;
$$;

COMMENT ON FUNCTION alert_rate.fn_home_basic_limit_m3(UUID) IS
'Devuelve el consumo básico mensual por altitud: 16, 13 u 11 m³. Sin altitud informada usa 16 m³ como referencia conservadora.';
