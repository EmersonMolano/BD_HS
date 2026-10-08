-- Vincula un ESP32 ya identificado por su hardwareId, sin exponer la IP.
CREATE OR REPLACE FUNCTION device.fn_link_device_to_home_by_hardware(
    p_hardware_id VARCHAR(32),
    p_home_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = device, home, user_account, public, pg_temp
AS $$
DECLARE
    v_device_id UUID;
    v_user_id UUID;
BEGIN
    v_user_id := user_account.fn_app_current_user_id();

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'El usuario autenticado es obligatorio';
    END IF;

    IF p_hardware_id IS NULL OR btrim(p_hardware_id) !~ '^[A-Za-z0-9_-]{3,32}$' THEN
        RAISE EXCEPTION 'hardwareId debe tener entre 3 y 32 caracteres seguros';
    END IF;

    IF NOT user_account.fn_app_has_permission('devices.manage')
       OR NOT home.fn_is_home_owner(p_home_id, v_user_id) THEN
        RAISE EXCEPTION 'La cuenta no puede vincular dispositivos a este hogar'
            USING ERRCODE = '42501';
    END IF;

    SELECT d.device_id
      INTO v_device_id
      FROM device.device d
     WHERE d.hardware_id = btrim(p_hardware_id)
       AND d.status = 'Active'
     LIMIT 1;

    IF v_device_id IS NULL THEN
        RETURN NULL;
    END IF;

    INSERT INTO home.home_device (home_id, device_id, status, suspended_at)
    VALUES (p_home_id, v_device_id, 'Active', NULL)
    ON CONFLICT (home_id, device_id)
    DO UPDATE SET status = 'Active', suspended_at = NULL;

    RETURN v_device_id;
END;
$$;

COMMENT ON FUNCTION device.fn_link_device_to_home_by_hardware(VARCHAR, UUID) IS
'Vincula un dispositivo activo a un hogar usando su identidad fisica hardwareId.';
