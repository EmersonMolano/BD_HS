-- El panel de tickets queda integrado en Administrator.
-- Se elimina únicamente el rol funcional y sus asignaciones; las cuentas
-- siguen existiendo y pueden conservar otros roles funcionales.
DELETE FROM user_account.role
 WHERE name = 'Support';
