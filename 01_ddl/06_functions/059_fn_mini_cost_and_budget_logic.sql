-- Logica simplificada de HidroSmart mini.
-- El sensor conserva litros; el costo se calcula en m3 con una sola tarifa
-- configurable por categoria. No se guardan cifras de ejemplo en el frontend.

CREATE OR REPLACE FUNCTION consumption.fn_calculate_cost(
    p_consumption_m3 DECIMAL,
    p_home_id UUID,
    p_date DATE
)
RETURNS DECIMAL(12,2)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = consumption, alert_rate, home, user_account, public, pg_temp
AS $$
DECLARE
    v_rate DECIMAL(12,4);
BEGIN
    IF p_consumption_m3 IS NULL THEN
        RETURN NULL;
    END IF;

    IF p_consumption_m3 < 0 THEN
        RAISE EXCEPTION 'El consumo no puede ser negativo';
    END IF;

    SELECT COALESCE(hr.m3_value, rr.basic_m3_value)
      INTO v_rate
      FROM home.home h
      LEFT JOIN LATERAL (
          SELECT r.m3_value
            FROM alert_rate.home_rate r
           WHERE r.home_id = h.home_id
             AND r.valid_from <= p_date
             AND (r.valid_until IS NULL OR r.valid_until >= p_date)
           ORDER BY r.valid_from DESC
           LIMIT 1
      ) hr ON TRUE
      LEFT JOIN LATERAL (
          SELECT r.basic_m3_value
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

    IF v_rate IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN ROUND(p_consumption_m3 * v_rate, 2);
END;
$$;

CREATE OR REPLACE FUNCTION consumption.fn_calculate_consumption(
    p_home_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    total_m3 NUMERIC,
    total_liters NUMERIC,
    total_cost NUMERIC,
    reading_count INTEGER
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = consumption, alert_rate, home, user_account, public, pg_temp
AS $$
BEGIN
    PERFORM user_account.fn_assert_app_home_access(p_home_id, 'consumption.read');

    IF p_start_date IS NULL OR p_end_date IS NULL OR p_end_date < p_start_date THEN
        RAISE EXCEPTION 'El rango de fechas no es valido';
    END IF;

    RETURN QUERY
    SELECT COALESCE(SUM(sr.consumption_m3), 0)::NUMERIC,
           COALESCE(SUM(sr.consumption_liters), 0)::NUMERIC,
           COALESCE(SUM(consumption.fn_calculate_cost(
               sr.consumption_m3,
               p_home_id,
               sr.recorded_at::DATE
           )), 0)::NUMERIC,
           COUNT(*)::INTEGER
      FROM consumption.sensor_reading sr
     WHERE sr.home_id = p_home_id
       AND sr.recorded_at >= p_start_date::TIMESTAMP
       AND sr.recorded_at < (p_end_date + 1)::TIMESTAMP;
END;
$$;

CREATE OR REPLACE FUNCTION analytics_support.fn_get_home_budget_status(
    p_home_id UUID,
    p_as_of_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    home_id UUID,
    as_of_date DATE,
    period_start DATE,
    period_end DATE,
    days_in_month INTEGER,
    day_of_month INTEGER,
    people_count INTEGER,
    reference_source VARCHAR(20),
    history_days INTEGER,
    expected_daily_liters NUMERIC,
    expected_weekly_liters NUMERIC,
    expected_monthly_liters NUMERIC,
    expected_to_date_liters NUMERIC,
    current_liters NUMERIC,
    current_m3 NUMERIC,
    current_cost NUMERIC,
    tariff_m3 NUMERIC,
    monthly_budget NUMERIC,
    expected_budget_to_date NUMERIC,
    budget_percentage NUMERIC,
    budget_pace_percentage NUMERIC,
    budget_status VARCHAR(20),
    remaining_budget NUMERIC,
    remaining_liters NUMERIC,
    consumption_pace_percentage NUMERIC,
    consumption_status VARCHAR(20)
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = analytics_support, consumption, alert_rate, home, user_account, public, pg_temp
AS $$
DECLARE
    v_home RECORD;
    v_reference RECORD;
    v_rate NUMERIC;
    v_goal RECORD;
    v_month_start DATE;
    v_month_end DATE;
    v_days_in_month INTEGER;
    v_day_of_month INTEGER;
    v_expected_daily_liters NUMERIC := 0;
    v_expected_weekly_liters NUMERIC := 0;
    v_expected_monthly_liters NUMERIC := 0;
    v_expected_to_date_liters NUMERIC := 0;
    v_reference_source VARCHAR(20) := 'NATIONAL_REFERENCE';
    v_history_days INTEGER := 0;
    v_history_average_daily_liters NUMERIC;
    v_current_liters NUMERIC := 0;
    v_current_m3 NUMERIC := 0;
    v_current_cost NUMERIC := 0;
    v_monthly_budget NUMERIC;
    v_expected_budget_to_date NUMERIC;
    v_budget_percentage NUMERIC;
    v_budget_pace_percentage NUMERIC;
    v_remaining_budget NUMERIC;
    v_remaining_liters NUMERIC;
    v_consumption_pace_percentage NUMERIC;
    v_budget_status VARCHAR(20);
    v_consumption_status VARCHAR(20);
BEGIN
    PERFORM user_account.fn_assert_app_home_access(p_home_id, 'reports.read');

    p_as_of_date := COALESCE(p_as_of_date, CURRENT_DATE);

    SELECT h.home_id, h.usage_type, h.tier, h.people_count
      INTO v_home
      FROM home.home h
     WHERE h.home_id = p_home_id;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    v_month_start := date_trunc('month', p_as_of_date)::DATE;
    v_month_end := (v_month_start + INTERVAL '1 month - 1 day')::DATE;
    v_days_in_month := v_month_end - v_month_start + 1;
    v_day_of_month := p_as_of_date - v_month_start + 1;

    -- Con 60 o mas dias previos disponibles, el hogar pasa a compararse
    -- contra su propio promedio. Las lecturas del mes actual no contaminan
    -- la referencia del periodo que se esta evaluando.
    SELECT COUNT(DISTINCT sr.recorded_at::DATE)::INTEGER,
           SUM(sr.consumption_liters) / NULLIF(COUNT(DISTINCT sr.recorded_at::DATE), 0)
      INTO v_history_days, v_history_average_daily_liters
      FROM consumption.sensor_reading sr
     WHERE sr.home_id = p_home_id
       AND sr.recorded_at::DATE >= (v_month_start - INTERVAL '3 months')::DATE
       AND sr.recorded_at::DATE < v_month_start;

    SELECT r.reference_consumption_m3,
           r.reference_person_daily_liters
      INTO v_reference
      FROM alert_rate.reference_rate r
     WHERE r.usage_type = v_home.usage_type
       AND r.tier IS NOT DISTINCT FROM v_home.tier
       AND r.active = TRUE
       AND r.valid_from <= p_as_of_date
       AND (r.valid_until IS NULL OR r.valid_until >= p_as_of_date)
     ORDER BY r.valid_from DESC
     LIMIT 1;

    SELECT COALESCE(hr.m3_value, rr.basic_m3_value)
      INTO v_rate
      FROM home.home h
      LEFT JOIN LATERAL (
          SELECT r.m3_value
            FROM alert_rate.home_rate r
           WHERE r.home_id = h.home_id
             AND r.valid_from <= p_as_of_date
             AND (r.valid_until IS NULL OR r.valid_until >= p_as_of_date)
           ORDER BY r.valid_from DESC
           LIMIT 1
      ) hr ON TRUE
      LEFT JOIN LATERAL (
          SELECT r.basic_m3_value
            FROM alert_rate.reference_rate r
           WHERE r.usage_type = h.usage_type
             AND r.tier IS NOT DISTINCT FROM h.tier
             AND r.active = TRUE
             AND r.valid_from <= p_as_of_date
             AND (r.valid_until IS NULL OR r.valid_until >= p_as_of_date)
           ORDER BY r.valid_from DESC
           LIMIT 1
      ) rr ON TRUE
     WHERE h.home_id = p_home_id;

    SELECT g.target_budget
      INTO v_goal
      FROM home.saving_goal g
     WHERE g.home_id = p_home_id
       AND g.type = 'monthly'
       AND g.period_start <= p_as_of_date
       AND (g.period_end IS NULL OR g.period_end >= p_as_of_date)
     ORDER BY g.period_start DESC, g.created_at DESC
     LIMIT 1;

    IF v_history_days >= 60 AND v_history_average_daily_liters IS NOT NULL THEN
        v_expected_daily_liters := v_history_average_daily_liters;
        v_reference_source := 'HOME_HISTORY';
    ELSIF v_home.usage_type = 'RESIDENTIAL' THEN
        v_expected_daily_liters := COALESCE(v_reference.reference_person_daily_liters, 123) * v_home.people_count;
    ELSE
        v_expected_daily_liters := COALESCE(v_reference.reference_consumption_m3, 0) * 1000 / v_days_in_month;
    END IF;
    v_expected_weekly_liters := v_expected_daily_liters * 7;
    v_expected_monthly_liters := v_expected_daily_liters * v_days_in_month;
    v_expected_to_date_liters := v_expected_daily_liters * v_day_of_month;

    SELECT COALESCE(SUM(sr.consumption_liters), 0),
           COALESCE(SUM(sr.consumption_m3), 0),
           COALESCE(SUM(consumption.fn_calculate_cost(
               sr.consumption_m3,
               p_home_id,
               sr.recorded_at::DATE
           )), 0)
      INTO v_current_liters, v_current_m3, v_current_cost
      FROM consumption.sensor_reading sr
     WHERE sr.home_id = p_home_id
       AND sr.recorded_at >= v_month_start::TIMESTAMP
       AND sr.recorded_at < (p_as_of_date + 1)::TIMESTAMP;

    v_monthly_budget := v_goal.target_budget;
    v_expected_budget_to_date := CASE
        WHEN v_monthly_budget IS NULL THEN NULL
        ELSE v_monthly_budget * v_day_of_month / v_days_in_month
    END;
    v_budget_percentage := CASE
        WHEN v_monthly_budget IS NULL OR v_monthly_budget = 0 THEN NULL
        ELSE ROUND(v_current_cost / v_monthly_budget * 100, 2)
    END;
    v_budget_pace_percentage := CASE
        WHEN v_expected_budget_to_date IS NULL OR v_expected_budget_to_date = 0 THEN NULL
        ELSE ROUND(v_current_cost / v_expected_budget_to_date * 100, 2)
    END;
    v_remaining_budget := CASE
        WHEN v_monthly_budget IS NULL THEN NULL
        ELSE GREATEST(v_monthly_budget - v_current_cost, 0)
    END;
    v_remaining_liters := CASE
        WHEN v_remaining_budget IS NULL OR COALESCE(v_rate, 0) <= 0 THEN NULL
        ELSE ROUND(v_remaining_budget / v_rate * 1000, 2)
    END;

    v_consumption_pace_percentage := CASE
        WHEN v_expected_to_date_liters = 0 THEN NULL
        ELSE ROUND(v_current_liters / v_expected_to_date_liters * 100, 2)
    END;

    v_budget_status := CASE
        WHEN v_budget_pace_percentage IS NULL THEN NULL
        WHEN v_budget_pace_percentage < 80 THEN 'NORMAL'
        WHEN v_budget_pace_percentage <= 100 THEN 'CAUTION'
        WHEN v_budget_pace_percentage <= 120 THEN 'HIGH'
        ELSE 'CRITICAL'
    END;

    v_consumption_status := CASE
        WHEN v_consumption_pace_percentage IS NULL THEN NULL
        WHEN v_consumption_pace_percentage < 80 THEN 'NORMAL'
        WHEN v_consumption_pace_percentage <= 100 THEN 'CAUTION'
        WHEN v_consumption_pace_percentage <= 120 THEN 'HIGH'
        ELSE 'CRITICAL'
    END;

    RETURN QUERY SELECT
        p_home_id,
        p_as_of_date,
        v_month_start,
        v_month_end,
        v_days_in_month,
        v_day_of_month,
        v_home.people_count::INTEGER,
        v_reference_source,
        v_history_days,
        ROUND(v_expected_daily_liters, 2),
        ROUND(v_expected_weekly_liters, 2),
        ROUND(v_expected_monthly_liters, 2),
        ROUND(v_expected_to_date_liters, 2),
        ROUND(v_current_liters, 3),
        ROUND(v_current_m3, 6),
        ROUND(v_current_cost, 2),
        COALESCE(v_rate, 0),
        v_monthly_budget,
        v_expected_budget_to_date,
        v_budget_percentage,
        v_budget_pace_percentage,
        v_budget_status,
        v_remaining_budget,
        v_remaining_liters,
        v_consumption_pace_percentage,
        v_consumption_status;
END;
$$;

COMMENT ON FUNCTION consumption.fn_calculate_cost(DECIMAL, UUID, DATE) IS
'Convierte m3 a costo estimado usando una tarifa unica vigente para el hogar.';

COMMENT ON FUNCTION consumption.fn_calculate_consumption(UUID, DATE, DATE) IS
'Calcula consumo real y costo estimado desde lecturas en litros, convertido a m3 en PostgreSQL.';

COMMENT ON FUNCTION analytics_support.fn_get_home_budget_status(UUID, DATE) IS
'Compara consumo y presupuesto contra el avance real del mes; usa dias reales, personas del hogar y litros restantes.';
