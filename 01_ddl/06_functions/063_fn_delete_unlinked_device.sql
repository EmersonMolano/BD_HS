-- Elimina un dispositivo fisico solamente cuando no pertenece a ningun hogar.
CREATE OR REPLACE FUNCTION device.fn_delete_unlinked_device(
    p_device_id UUID
)
RETURNS VARCHAR(20)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = device, home, user_account, public, pg_temp
AS $$
BEGIN
    IF user_account.fn_app_current_user_id() IS NULL THEN
        RAISE EXCEPTION 'El usuario autenticado es obligatorio';
    END IF;

    IF NOT user_account.fn_app_has_permission('devices.manage') THEN
        RAISE EXCEPTION 'La cuenta no puede eliminar dispositivos'
            USING ERRCODE = '42501';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM home.home_device
         WHERE device_id = p_device_id
    ) THEN
        RETURN 'LINKED';
    END IF;

    DELETE FROM device.device
     WHERE device_id = p_device_id;

    IF FOUND THEN
        RETURN 'DELETED';
    END IF;

    RETURN 'NOT_FOUND';
END;
$$;

COMMENT ON FUNCTION device.fn_delete_unlinked_device(UUID) IS
'Elimina un dispositivo y su historial en cascada solo cuando ya fue desvinculado de todos los hogares.';
