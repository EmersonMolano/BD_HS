-- Persiste el costo estimado por lectura con la tarifa vigente del hogar.
-- El valor original del sensor sigue siendo consumption_liters.

CREATE OR REPLACE FUNCTION consumption.fn_set_estimated_cost()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = consumption, alert_rate, home, public, pg_temp
AS $$
BEGIN
    NEW.estimated_cost := consumption.fn_calculate_cost(
        NEW.consumption_liters / 1000,
        NEW.home_id,
        NEW.recorded_at::DATE
    );
    NEW.cost_calculated_at := now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sensor_reading_estimated_cost ON consumption.sensor_reading;

CREATE TRIGGER trg_sensor_reading_estimated_cost
    BEFORE INSERT OR UPDATE OF home_id, recorded_at, consumption_liters
    ON consumption.sensor_reading
    FOR EACH ROW
    EXECUTE FUNCTION consumption.fn_set_estimated_cost();

-- Normaliza lecturas históricas para que los resúmenes materializados no queden
-- con costo cero después de activar la tarifa simplificada.
UPDATE consumption.sensor_reading sr
   SET estimated_cost = consumption.fn_calculate_cost(
           sr.consumption_liters / 1000,
           sr.home_id,
           sr.recorded_at::DATE
       ),
       cost_calculated_at = now()
 WHERE sr.estimated_cost IS NULL;
