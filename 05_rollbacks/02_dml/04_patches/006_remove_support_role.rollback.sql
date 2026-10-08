INSERT INTO user_account.role (role_id, name, description, status)
SELECT gen_random_uuid(), 'Support', 'Gestión de dispositivos, tickets y soporte técnico', 'Active'
WHERE NOT EXISTS (
    SELECT 1 FROM user_account.role WHERE name = 'Support'
);

WITH role_permissions(role_name, permission_name) AS (
    VALUES
        ('Support', 'devices.manage'),
        ('Support', 'consumption.read'),
        ('Support', 'alerts.manage'),
        ('Support', 'tickets.manage')
)
INSERT INTO user_account.role_permission (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM role_permissions rp
JOIN user_account.role r ON r.name = rp.role_name
JOIN user_account.permission p ON p.name = rp.permission_name
ON CONFLICT DO NOTHING;
