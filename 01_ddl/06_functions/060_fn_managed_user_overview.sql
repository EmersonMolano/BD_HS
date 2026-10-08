CREATE OR REPLACE FUNCTION user_account.fn_get_managed_user_overview(
    p_target_user_id UUID
)
RETURNS TABLE (
    user_account_id UUID,
    username VARCHAR,
    email VARCHAR,
    status VARCHAR,
    full_name VARCHAR,
    homes JSONB,
    devices JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = user_account, home, device, public, pg_temp
AS $$
BEGIN
    IF NOT user_account.fn_app_has_permission('users.manage') THEN
        RAISE EXCEPTION 'La cuenta no puede consultar el detalle administrativo de usuarios';
    END IF;

    RETURN QUERY
    SELECT ua.user_account_id,
           ua.username,
           ua.email,
           ua.status,
           up.full_name,
           COALESCE((
               SELECT jsonb_agg(
                   jsonb_build_object(
                       'homeId', h.home_id,
                       'name', h.name,
                       'address', h.address,
                       'city', h.city,
                       'tier', h.tier,
                       'status', h.status,
                       'homeRole', hu.home_role,
                       'deviceCount', (
                           SELECT count(*)
                             FROM home.home_device hd_count
                            WHERE hd_count.home_id = h.home_id
                              AND hd_count.status <> 'Suspended'
                       )
                   ) ORDER BY h.name
               )
                 FROM home.home_user hu
                 JOIN home.home h ON h.home_id = hu.home_id
                WHERE hu.user_account_id = ua.user_account_id
                  AND h.deleted_at IS NULL
           ), '[]'::jsonb) AS homes,
           COALESCE((
               SELECT jsonb_agg(
                   jsonb_build_object(
                       'deviceId', d.device_id,
                       'code', d.code,
                       'name', d.name,
                       'type', d.type,
                       'status', d.status,
                       'homeId', h.home_id,
                       'homeName', h.name,
                       'location', d.location,
                       'hardwareId', d.hardware_id,
                       'connectivityStatus', d.connectivity_status,
                       'provisioningStatus', d.provisioning_status,
                       'lastConnectionAt', d.last_connection_at,
                       'signalQuality', d.signal_quality,
                       'batteryLevel', d.battery_level
                   ) ORDER BY d.name
               )
                 FROM home.home_user hu
                 JOIN home.home h ON h.home_id = hu.home_id
                 JOIN home.home_device hd ON hd.home_id = h.home_id
                 JOIN device.device d ON d.device_id = hd.device_id
                WHERE hu.user_account_id = ua.user_account_id
                  AND h.deleted_at IS NULL
           ), '[]'::jsonb) AS devices
      FROM user_account.user_account ua
      LEFT JOIN user_account.user_profile up
        ON up.user_account_id = ua.user_account_id
     WHERE ua.user_account_id = p_target_user_id
       AND ua.deleted_at IS NULL;
END;
$$;

REVOKE ALL ON FUNCTION user_account.fn_get_managed_user_overview(UUID) FROM PUBLIC;
