-- Variante de creacion de hogar que persiste el numero de personas.
-- Mantiene la funcion anterior para compatibilidad con clientes existentes.

CREATE OR REPLACE FUNCTION home.fn_create_home_with_billing_profile(
    p_name VARCHAR(100),
    p_address VARCHAR(255),
    p_city VARCHAR(100),
    p_tier SMALLINT DEFAULT NULL,
    p_user_account_id UUID DEFAULT user_account.fn_app_current_user_id(),
    p_usage_type VARCHAR(20) DEFAULT 'RESIDENTIAL',
    p_altitude_meters INTEGER DEFAULT NULL,
    p_people_count SMALLINT DEFAULT 3
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

    IF p_people_count IS NULL OR p_people_count NOT BETWEEN 1 AND 50 THEN
        RAISE EXCEPTION 'people_count debe estar entre 1 y 50';
    END IF;

    INSERT INTO home.home (
        name,
        address,
        city,
        tier,
        usage_type,
        altitude_meters,
        people_count
    )
    VALUES (
        p_name,
        p_address,
        p_city,
        p_tier,
        v_usage_type,
        p_altitude_meters,
        p_people_count
    )
    RETURNING home_id INTO v_home_id;

    INSERT INTO home.home_user (home_id, user_account_id, home_role, added_by)
    VALUES (v_home_id, p_user_account_id, 'Owner', p_user_account_id);

    PERFORM home.fn_sync_home_reference_rate(v_home_id);
    RETURN v_home_id;
END;
$$;

COMMENT ON FUNCTION home.fn_create_home_with_billing_profile(VARCHAR, VARCHAR, VARCHAR, SMALLINT, UUID, VARCHAR, INTEGER, SMALLINT) IS
'Crea un hogar tipado con estrato condicional, altitud y numero de personas para las referencias de HidroSmart mini.';
