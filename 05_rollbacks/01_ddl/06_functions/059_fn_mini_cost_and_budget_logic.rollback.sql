-- El rollback conserva las funciones 057 previas mediante el changelog historico.
-- Se eliminan solo las funciones nuevas de presupuesto y se deja la firma de
-- costo disponible para que el changeset previo la restaure en orden inverso.

DROP FUNCTION IF EXISTS analytics_support.fn_get_home_budget_status(UUID, DATE);
