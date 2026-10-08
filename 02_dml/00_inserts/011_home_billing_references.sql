-- Referencias nacionales iniciales para cálculo de costos.
-- Son benchmarks técnicos y deben reemplazarse por la tarifa real del
-- prestador cuando el hogar la configure.

UPDATE alert_rate.estratos
   SET valor_base_m3 = CASE numero_estrato
           WHEN 1 THEN 5200.00
           WHEN 2 THEN 4083.33
           WHEN 3 THEN 4000.00
           WHEN 4 THEN 3900.00
           WHEN 5 THEN 3933.33
           WHEN 6 THEN 3937.50
       END,
       subsidio_porcentaje = CASE numero_estrato
           WHEN 1 THEN 70.00
           WHEN 2 THEN 40.00
           WHEN 3 THEN 15.00
           WHEN 4 THEN 0.00
           WHEN 5 THEN -50.00
           WHEN 6 THEN -60.00
       END,
       fecha_actualizacion = now()
 WHERE numero_estrato BETWEEN 1 AND 6;

INSERT INTO alert_rate.reference_rate (
    usage_type,
    tier,
    basic_m3_value,
    excess_m3_value,
    reference_consumption_m3,
    subsidy_percentage,
    solidarity_percentage,
    source_note,
    valid_from
)
SELECT source.usage_type,
       source.tier,
       source.basic_m3_value,
       source.excess_m3_value,
       source.reference_consumption_m3,
       source.subsidy_percentage,
       source.solidarity_percentage,
       source.source_note,
       DATE '2026-01-01'
  FROM (VALUES
      ('RESIDENTIAL', 1::smallint, 1560.00::numeric, 5200.00::numeric, 11.81::numeric, 70.00::numeric, 0.00::numeric, 'Benchmark nacional HidroSmart: Superservicios/SUI 2024 y referencias oficiales 2026'),
      ('RESIDENTIAL', 2::smallint, 2450.00::numeric, 4083.33::numeric, 11.18::numeric, 40.00::numeric, 0.00::numeric, 'Benchmark nacional HidroSmart: Superservicios/SUI 2024 y referencias oficiales 2026'),
      ('RESIDENTIAL', 3::smallint, 3400.00::numeric, 4000.00::numeric, 10.12::numeric, 15.00::numeric, 0.00::numeric, 'Benchmark nacional HidroSmart: Superservicios/SUI 2024 y referencias oficiales 2026'),
      ('RESIDENTIAL', 4::smallint, 3900.00::numeric, 3900.00::numeric, 10.17::numeric, 0.00::numeric, 0.00::numeric, 'Benchmark nacional HidroSmart: Superservicios/SUI 2024 y referencias oficiales 2026'),
      ('RESIDENTIAL', 5::smallint, 5900.00::numeric, 3933.33::numeric, 10.94::numeric, 0.00::numeric, 50.00::numeric, 'Benchmark nacional HidroSmart: Superservicios/SUI 2024 y referencias oficiales 2026'),
      ('RESIDENTIAL', 6::smallint, 6300.00::numeric, 3937.50::numeric, 13.19::numeric, 0.00::numeric, 60.00::numeric, 'Benchmark nacional HidroSmart: Superservicios/SUI 2024 y referencias oficiales 2026'),
      ('COMMERCIAL', NULL::smallint, 5850.00::numeric, 5850.00::numeric, 17.90::numeric, 0.00::numeric, 50.00::numeric, 'Referencia estadística aproximada: consumo no residencial variable'),
      ('INDUSTRIAL', NULL::smallint, 5150.00::numeric, 5150.00::numeric, 170.50::numeric, 0.00::numeric, 30.00::numeric, 'Referencia estadística aproximada: consumo no residencial variable')
  ) AS source(
      usage_type,
      tier,
      basic_m3_value,
      excess_m3_value,
      reference_consumption_m3,
      subsidy_percentage,
      solidarity_percentage,
      source_note
  )
 WHERE NOT EXISTS (
     SELECT 1
       FROM alert_rate.reference_rate existing
      WHERE existing.usage_type = source.usage_type
        AND existing.tier IS NOT DISTINCT FROM source.tier
        AND existing.valid_from = DATE '2026-01-01'
 );

-- Los hogares existentes reciben una referencia solo si aún no tenían tarifa.
INSERT INTO alert_rate.home_rate (
    home_id,
    usage_type,
    tier,
    m3_value,
    basic_m3_value,
    excess_m3_value,
    reference_consumption_m3,
    fixed_charge,
    valid_from,
    rate_source,
    unit_sensor,
    unit_billing
)
SELECT h.home_id,
       rr.usage_type,
       rr.tier,
       rr.basic_m3_value,
       rr.basic_m3_value,
       rr.excess_m3_value,
       rr.reference_consumption_m3,
       0,
       rr.valid_from,
       'NATIONAL_FALLBACK',
       rr.unit_sensor,
       rr.unit_billing
  FROM home.home h
  JOIN LATERAL (
      SELECT r.*
        FROM alert_rate.reference_rate r
       WHERE r.usage_type = h.usage_type
         AND r.tier IS NOT DISTINCT FROM h.tier
         AND r.active = TRUE
         AND r.valid_from <= CURRENT_DATE
         AND (r.valid_until IS NULL OR r.valid_until >= CURRENT_DATE)
       ORDER BY r.valid_from DESC
       LIMIT 1
  ) rr ON TRUE
 WHERE NOT EXISTS (
     SELECT 1
       FROM alert_rate.home_rate current_rate
      WHERE current_rate.home_id = h.home_id
        AND current_rate.valid_until IS NULL
 );
