-- Defaults simplificados para HidroSmart mini.
-- Son referencias de desarrollo, no una tarifa nacional oficial.

UPDATE alert_rate.reference_rate
   SET basic_m3_value = CASE
           WHEN usage_type = 'RESIDENTIAL' AND tier = 1 THEN 1025.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 2 THEN 2050.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 3 THEN 3100.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 4 THEN 3415.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 5 THEN 5175.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 6 THEN 5515.00
           WHEN usage_type = 'COMMERCIAL' THEN 5200.00
           WHEN usage_type = 'INDUSTRIAL' THEN 4750.00
       END,
       excess_m3_value = CASE
           WHEN usage_type = 'RESIDENTIAL' AND tier = 1 THEN 1025.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 2 THEN 2050.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 3 THEN 3100.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 4 THEN 3415.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 5 THEN 5175.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 6 THEN 5515.00
           WHEN usage_type = 'COMMERCIAL' THEN 5200.00
           WHEN usage_type = 'INDUSTRIAL' THEN 4750.00
       END,
       reference_consumption_m3 = CASE
           WHEN usage_type = 'RESIDENTIAL' THEN 10.68
           WHEN usage_type = 'COMMERCIAL' THEN 17.90
           WHEN usage_type = 'INDUSTRIAL' THEN 170.50
       END,
       reference_people_count = CASE WHEN usage_type = 'RESIDENTIAL' THEN 2.86 ELSE NULL END,
       reference_person_daily_liters = CASE WHEN usage_type = 'RESIDENTIAL' THEN 123.00 ELSE NULL END,
       source_note = CASE
           WHEN usage_type = 'RESIDENTIAL' THEN 'HidroSmart mini: referencia residencial 2025 de Superservicios/SUI y DANE; tarifa tecnica aproximada 2026'
           ELSE 'HidroSmart mini: referencia estadistica aproximada para uso no residencial; tarifa tecnica aproximada 2026'
       END
 WHERE valid_from = DATE '2026-01-01'
   AND active = TRUE;

-- Solo se actualizan referencias nacionales; las tarifas USER_CONFIGURED quedan intactas.
UPDATE alert_rate.home_rate
   SET m3_value = CASE
           WHEN usage_type = 'RESIDENTIAL' AND tier = 1 THEN 1025.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 2 THEN 2050.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 3 THEN 3100.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 4 THEN 3415.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 5 THEN 5175.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 6 THEN 5515.00
           WHEN usage_type = 'COMMERCIAL' THEN 5200.00
           WHEN usage_type = 'INDUSTRIAL' THEN 4750.00
       END,
       basic_m3_value = CASE
           WHEN usage_type = 'RESIDENTIAL' AND tier = 1 THEN 1025.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 2 THEN 2050.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 3 THEN 3100.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 4 THEN 3415.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 5 THEN 5175.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 6 THEN 5515.00
           WHEN usage_type = 'COMMERCIAL' THEN 5200.00
           WHEN usage_type = 'INDUSTRIAL' THEN 4750.00
       END,
       excess_m3_value = CASE
           WHEN usage_type = 'RESIDENTIAL' AND tier = 1 THEN 1025.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 2 THEN 2050.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 3 THEN 3100.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 4 THEN 3415.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 5 THEN 5175.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 6 THEN 5515.00
           WHEN usage_type = 'COMMERCIAL' THEN 5200.00
           WHEN usage_type = 'INDUSTRIAL' THEN 4750.00
       END,
       reference_consumption_m3 = CASE
           WHEN usage_type = 'RESIDENTIAL' THEN 10.68
           WHEN usage_type = 'COMMERCIAL' THEN 17.90
           WHEN usage_type = 'INDUSTRIAL' THEN 170.50
       END,
       updated_at = now()
 WHERE rate_source = 'NATIONAL_FALLBACK'
   AND valid_until IS NULL;
