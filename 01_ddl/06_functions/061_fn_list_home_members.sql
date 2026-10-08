-- Devuelve los miembros visibles de un hogar al que pertenece el usuario actual.
-- SECURITY DEFINER evita que el RLS de identidad propia oculte a los demas
-- miembros, pero la funcion valida primero que el usuario pertenezca al hogar.

CREATE OR REPLACE FUNCTION home.fn_list_home_members(
    p_home_id UUID
)
RETURNS TABLE (
    user_id UUID,
    username VARCHAR(100),
    full_name VARCHAR(200),
    home_role VARCHAR(20),
    assigned_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = home, user_account, public, pg_temp
AS $$
    SELECT ua.user_account_id,
           ua.username,
           up.full_name,
           hu.home_role,
           hu.assigned_at
      FROM home.home_user hu
      JOIN user_account.user_account ua
        ON ua.user_account_id = hu.user_account_id
      LEFT JOIN user_account.user_profile up
        ON up.user_account_id = ua.user_account_id
     WHERE hu.home_id = p_home_id
       AND ua.deleted_at IS NULL
       AND home.fn_is_home_member(p_home_id, user_account.fn_app_current_user_id())
     ORDER BY CASE hu.home_role
                  WHEN 'Owner' THEN 1
                  WHEN 'Member' THEN 2
                  ELSE 3
              END,
              hu.assigned_at;
$$;

COMMENT ON FUNCTION home.fn_list_home_members(UUID) IS
'Devuelve nombres y roles de todos los miembros de un hogar autorizado sin exponer sus correos.';
