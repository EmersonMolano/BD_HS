-- Clasificación de uso del hogar y catálogo de referencias nacionales.
-- Las referencias son valores iniciales editables; no representan una tarifa
-- nacional oficial única ni sustituyen la tarifa del prestador local.

ALTER TABLE home.home
    ADD COLUMN IF NOT EXISTS usage_type VARCHAR(20);

UPDATE home.home
   SET usage_type = 'RESIDENTIAL'
 WHERE usage_type IS NULL;

ALTER TABLE home.home
    ALTER COLUMN usage_type SET DEFAULT 'RESIDENTIAL',
    ALTER COLUMN usage_type SET NOT NULL;

ALTER TABLE home.home
    DROP CONSTRAINT IF EXISTS ck_home_usage_type;

ALTER TABLE home.home
    ADD CONSTRAINT ck_home_usage_type
        CHECK (usage_type IN ('RESIDENTIAL', 'COMMERCIAL', 'INDUSTRIAL'));

ALTER TABLE home.home
    ADD COLUMN IF NOT EXISTS altitude_meters INTEGER NULL;

ALTER TABLE home.home
    DROP CONSTRAINT IF EXISTS ck_home_altitude_meters;

ALTER TABLE home.home
    ADD CONSTRAINT ck_home_altitude_meters
        CHECK (altitude_meters IS NULL OR altitude_meters BETWEEN 0 AND 10000);

ALTER TABLE home.home
    DROP CONSTRAINT IF EXISTS ck_home_usage_type_tier;

ALTER TABLE home.home
    ADD CONSTRAINT ck_home_usage_type_tier
        CHECK (
            (usage_type = 'RESIDENTIAL' AND (tier IS NULL OR tier BETWEEN 1 AND 6))
            OR (usage_type IN ('COMMERCIAL', 'INDUSTRIAL') AND tier IS NULL)
        );

CREATE TABLE IF NOT EXISTS alert_rate.reference_rate (
    reference_rate_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usage_type VARCHAR(20) NOT NULL,
    tier SMALLINT NULL,
    basic_m3_value DECIMAL(12,4) NOT NULL CHECK (basic_m3_value >= 0),
    excess_m3_value DECIMAL(12,4) NOT NULL CHECK (excess_m3_value >= 0),
    reference_consumption_m3 DECIMAL(10,2) NOT NULL CHECK (reference_consumption_m3 > 0),
    subsidy_percentage DECIMAL(5,2) NOT NULL DEFAULT 0 CHECK (subsidy_percentage BETWEEN 0 AND 100),
    solidarity_percentage DECIMAL(5,2) NOT NULL DEFAULT 0 CHECK (solidarity_percentage BETWEEN 0 AND 100),
    source_note VARCHAR(255) NOT NULL,
    unit_sensor VARCHAR(10) NOT NULL DEFAULT 'L' CHECK (unit_sensor = 'L'),
    unit_billing VARCHAR(10) NOT NULL DEFAULT 'm3' CHECK (unit_billing = 'm3'),
    valid_from DATE NOT NULL,
    valid_until DATE NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NULL,

    CONSTRAINT ck_reference_rate_usage_tier CHECK (
        (usage_type = 'RESIDENTIAL' AND tier BETWEEN 1 AND 6)
        OR (usage_type IN ('COMMERCIAL', 'INDUSTRIAL') AND tier IS NULL)
    ),
    CONSTRAINT ck_reference_rate_usage_type CHECK (
        usage_type IN ('RESIDENTIAL', 'COMMERCIAL', 'INDUSTRIAL')
    ),
    CONSTRAINT ck_reference_rate_validity CHECK (
        valid_until IS NULL OR valid_until >= valid_from
    ),
    CONSTRAINT fk_reference_rate_tier_estrato FOREIGN KEY (tier)
        REFERENCES alert_rate.estratos(numero_estrato)
        ON DELETE RESTRICT
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_reference_rate_category_valid_from
    ON alert_rate.reference_rate (usage_type, COALESCE(tier, 0), valid_from);

ALTER TABLE alert_rate.home_rate
    ALTER COLUMN tier DROP NOT NULL;

ALTER TABLE alert_rate.home_rate
    ADD COLUMN IF NOT EXISTS usage_type VARCHAR(20);

UPDATE alert_rate.home_rate hr
   SET usage_type = h.usage_type
  FROM home.home h
 WHERE h.home_id = hr.home_id
   AND hr.usage_type IS NULL;

UPDATE alert_rate.home_rate
   SET usage_type = 'RESIDENTIAL'
 WHERE usage_type IS NULL;

ALTER TABLE alert_rate.home_rate
    ALTER COLUMN usage_type SET DEFAULT 'RESIDENTIAL',
    ALTER COLUMN usage_type SET NOT NULL;

ALTER TABLE alert_rate.home_rate
    ADD COLUMN IF NOT EXISTS basic_m3_value DECIMAL(12,4);

ALTER TABLE alert_rate.home_rate
    ADD COLUMN IF NOT EXISTS excess_m3_value DECIMAL(12,4);

UPDATE alert_rate.home_rate
   SET basic_m3_value = m3_value
 WHERE basic_m3_value IS NULL;

UPDATE alert_rate.home_rate
   SET excess_m3_value = m3_value
 WHERE excess_m3_value IS NULL;

ALTER TABLE alert_rate.home_rate
    ALTER COLUMN basic_m3_value SET NOT NULL,
    ALTER COLUMN excess_m3_value SET NOT NULL;

ALTER TABLE alert_rate.home_rate
    ADD COLUMN IF NOT EXISTS reference_consumption_m3 DECIMAL(10,2) NULL
        CHECK (reference_consumption_m3 IS NULL OR reference_consumption_m3 > 0),
    ADD COLUMN IF NOT EXISTS rate_source VARCHAR(30) NOT NULL DEFAULT 'USER_CONFIGURED'
        CHECK (rate_source IN ('NATIONAL_FALLBACK', 'USER_CONFIGURED')),
    ADD COLUMN IF NOT EXISTS unit_sensor VARCHAR(10) NOT NULL DEFAULT 'L'
        CHECK (unit_sensor = 'L'),
    ADD COLUMN IF NOT EXISTS unit_billing VARCHAR(10) NOT NULL DEFAULT 'm3'
        CHECK (unit_billing = 'm3');

ALTER TABLE alert_rate.home_rate
    DROP CONSTRAINT IF EXISTS ck_home_rate_usage_type_tier;

ALTER TABLE alert_rate.home_rate
    ADD CONSTRAINT ck_home_rate_usage_type_tier CHECK (
        (usage_type = 'RESIDENTIAL' AND tier BETWEEN 1 AND 6)
        OR (usage_type IN ('COMMERCIAL', 'INDUSTRIAL') AND tier IS NULL)
    );

COMMENT ON COLUMN home.home.usage_type IS
'Uso del inmueble: residencial, comercial o industrial. El estrato solo aplica a residencial.';

COMMENT ON COLUMN home.home.altitude_meters IS
'Altitud aproximada del hogar en metros sobre el nivel del mar para determinar consumo básico.';

COMMENT ON TABLE alert_rate.reference_rate IS
'Valores nacionales de referencia para iniciar cálculos cuando aún no existe tarifa del prestador local.';
