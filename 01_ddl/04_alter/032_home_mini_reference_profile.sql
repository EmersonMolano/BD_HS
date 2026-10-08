-- Perfil minimo para Hidro_Smart mini.
-- people_count permite estimar consumo sin confundir personas con hogares.

ALTER TABLE home.home
    ADD COLUMN IF NOT EXISTS people_count SMALLINT NOT NULL DEFAULT 3;

ALTER TABLE home.home
    DROP CONSTRAINT IF EXISTS ck_home_people_count;

ALTER TABLE home.home
    ADD CONSTRAINT ck_home_people_count CHECK (people_count BETWEEN 1 AND 50);

ALTER TABLE alert_rate.reference_rate
    ADD COLUMN IF NOT EXISTS reference_people_count NUMERIC(4,2) NULL
        CHECK (reference_people_count IS NULL OR reference_people_count > 0);

ALTER TABLE alert_rate.reference_rate
    ADD COLUMN IF NOT EXISTS reference_person_daily_liters NUMERIC(8,3) NULL
        CHECK (reference_person_daily_liters IS NULL OR reference_person_daily_liters > 0);

COMMENT ON COLUMN home.home.people_count IS
'Cantidad de personas del hogar usada para la referencia de consumo; no reemplaza las lecturas reales.';

COMMENT ON COLUMN alert_rate.reference_rate.reference_people_count IS
'Tamaño promedio del hogar utilizado para construir la referencia nacional.';

COMMENT ON COLUMN alert_rate.reference_rate.reference_person_daily_liters IS
'Litros diarios aproximados por persona para HidroSmart mini.';
