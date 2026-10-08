-- E5, E6 y usos no residenciales usan una tarifa unica por m3.
-- El tramo excedente solo existe para E1-E3 por el consumo basico subsidiado.

UPDATE alert_rate.reference_rate
   SET excess_m3_value = basic_m3_value
 WHERE usage_type IN ('RESIDENTIAL', 'COMMERCIAL', 'INDUSTRIAL')
   AND (usage_type <> 'RESIDENTIAL' OR tier NOT IN (1, 2, 3));

UPDATE alert_rate.home_rate
   SET excess_m3_value = basic_m3_value
 WHERE rate_source = 'NATIONAL_FALLBACK'
   AND (usage_type <> 'RESIDENTIAL' OR tier NOT IN (1, 2, 3));
