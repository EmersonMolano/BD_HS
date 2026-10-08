-- Revierte la correccion de datos aplicada a las tarifas nacionales.

UPDATE alert_rate.reference_rate
   SET excess_m3_value = CASE
       WHEN usage_type = 'RESIDENTIAL' AND tier = 5 THEN 3933.33
       WHEN usage_type = 'RESIDENTIAL' AND tier = 6 THEN 3937.50
       ELSE basic_m3_value
   END
 WHERE valid_from = DATE '2026-01-01'
   AND usage_type IN ('RESIDENTIAL', 'COMMERCIAL', 'INDUSTRIAL');

UPDATE alert_rate.home_rate
   SET excess_m3_value = CASE
       WHEN usage_type = 'RESIDENTIAL' AND tier = 5 THEN 3933.33
       WHEN usage_type = 'RESIDENTIAL' AND tier = 6 THEN 3937.50
       ELSE basic_m3_value
   END
 WHERE rate_source = 'NATIONAL_FALLBACK';
