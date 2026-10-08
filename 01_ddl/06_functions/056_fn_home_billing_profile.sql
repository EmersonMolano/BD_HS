-- Crea hogares con su clasificación de uso y les asigna la referencia
-- nacional vigente sin almacenar credenciales ni datos sensibles.

CREATE OR REPLACE FUNCTION home.fn_sync_home_reference_rate(p_home_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = home, alert_rate, public, pg_temp
AS $$
DECLARE
    v_home RECORD;
    v_reference RECORD;
    v_current RECORD;
BEGIN
    SELECT h.home_id, h.usage_type, h.tier
      INTO v_home
      FROM home.home h
     WHERE h.home_id = p_home_id;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    SELECT r.*
      INTO v_reference
      FROM alert_rate.reference_rate r
     WHERE r.usage_type = v_home.usage_type
       AND r.tier IS NOT DISTINCT FROM v_home.tier
       AND r.active = TRUE
       AND r.valid_from <= CURRENT_DATE
       AND (r.valid_until IS NULL OR r.valid_until >= CURRENT_DATE)
     ORDER BY r.valid_from DESC
     LIMIT 1;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    SELECT hr.rate_id, hr.rate_source, hr.fixed_charge
      INTO v_current
      FROM alert_rate.home_rate hr
     WHERE hr.home_id = p_home_id
       AND (hr.valid_until IS NULL OR hr.valid_until >= CURRENT_DATE)
     ORDER BY hr.valid_from DESC
     LIMIT 1;

    IF FOUND AND v_current.rate_source = 'USER_CONFIGURED' THEN
        RETURN TRUE;
    END IF;

    IF FOUND THEN
        UPDATE alert_rate.home_rate
           SET usage_type = v_reference.usage_type,
               tier = v_reference.tier,
               m3_value = v_reference.basic_m3_value,
               basic_m3_value = v_reference.basic_m3_value,
               excess_m3_value = v_reference.excess_m3_value,
               reference_consumption_m3 = v_reference.reference_consumption_m3,
               rate_source = 'NATIONAL_FALLBACK',
               unit_sensor = v_reference.unit_sensor,
               unit_billing = v_reference.unit_billing,
               updated_at = now()
         WHERE rate_id = v_current.rate_id;
    ELSE
        INSERT INTO alert_rate.home_rate (
            home_id,
            usage_type,
            tier,
            m3_value,
            basic_m3_value,
            excess_m3_value,
            reference_consumption_m3,
            fixed_charge,
            valid_from,
            rate_source,
            unit_sensor,
            unit_billing
        )
        VALUES (
            p_home_id,
            v_reference.usage_type,
            v_reference.tier,
            v_reference.basic_m3_value,
            v_reference.basic_m3_value,
            v_reference.excess_m3_value,
            v_reference.reference_consumption_m3,
            0,
            v_reference.valid_from,
            'NATIONAL_FALLBACK',
            v_reference.unit_sensor,
            v_reference.unit_billing
        );
    END IF;

    RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION home.fn_create_home_with_billing_profile(
    p_name VARCHAR(100),
    p_address VARCHAR(255),
    p_city VARCHAR(100),
    p_tier SMALLINT DEFAULT NULL,
    p_user_account_id UUID DEFAULT user_account.fn_app_current_user_id(),
    p_usage_type VARCHAR(20) DEFAULT 'RESIDENTIAL',
    p_altitude_meters INTEGER DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = home, alert_rate, user_account, public, pg_temp
AS $$
DECLARE
    v_home_id UUID;
    v_usage_type VARCHAR(20) := upper(btrim(COALESCE(p_usage_type, 'RESIDENTIAL')));
BEGIN
    IF p_user_account_id IS NULL
       OR p_user_account_id <> user_account.fn_app_current_user_id() THEN
        RAISE EXCEPTION 'El propietario debe coincidir con el usuario autenticado';
    END IF;

    IF v_usage_type NOT IN ('RESIDENTIAL', 'COMMERCIAL', 'INDUSTRIAL') THEN
        RAISE EXCEPTION 'usage_type debe ser RESIDENTIAL, COMMERCIAL o INDUSTRIAL';
    END IF;

    IF v_usage_type = 'RESIDENTIAL' AND p_tier IS NULL THEN
        RAISE EXCEPTION 'El estrato es obligatorio para un hogar residencial';
    END IF;

    IF v_usage_type IN ('COMMERCIAL', 'INDUSTRIAL') AND p_tier IS NOT NULL THEN
        RAISE EXCEPTION 'Los usos comercial e industrial no tienen estrato';
    END IF;

    INSERT INTO home.home (
        name,
        address,
        city,
        tier,
        usage_type,
        altitude_meters
    )
    VALUES (
        p_name,
        p_address,
        p_city,
        p_tier,
        v_usage_type,
        p_altitude_meters
    )
    RETURNING home_id INTO v_home_id;

    INSERT INTO home.home_user (home_id, user_account_id, home_role, added_by)
    VALUES (v_home_id, p_user_account_id, 'Owner', p_user_account_id);

    PERFORM home.fn_sync_home_reference_rate(v_home_id);
    RETURN v_home_id;
END;
$$;

COMMENT ON FUNCTION home.fn_create_home_with_billing_profile(VARCHAR, VARCHAR, VARCHAR, SMALLINT, UUID, VARCHAR, INTEGER) IS
'Crea un hogar, valida su uso residencial/no residencial, registra al propietario y asigna una tarifa de referencia vigente.';
