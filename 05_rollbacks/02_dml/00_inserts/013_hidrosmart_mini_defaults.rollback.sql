-- Restaura los valores nacionales que existian antes de HidroSmart mini.

UPDATE alert_rate.reference_rate
   SET basic_m3_value = CASE
           WHEN usage_type = 'RESIDENTIAL' AND tier = 1 THEN 1560.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 2 THEN 2450.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 3 THEN 3400.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 4 THEN 3900.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 5 THEN 5900.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 6 THEN 6300.00
           WHEN usage_type = 'COMMERCIAL' THEN 5850.00
           WHEN usage_type = 'INDUSTRIAL' THEN 5150.00
       END,
       excess_m3_value = CASE
           WHEN usage_type = 'RESIDENTIAL' AND tier = 1 THEN 5200.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 2 THEN 4083.33
           WHEN usage_type = 'RESIDENTIAL' AND tier = 3 THEN 4000.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 4 THEN 3900.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 5 THEN 5900.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 6 THEN 6300.00
           WHEN usage_type = 'COMMERCIAL' THEN 5850.00
           WHEN usage_type = 'INDUSTRIAL' THEN 5150.00
       END,
       reference_consumption_m3 = CASE
           WHEN usage_type = 'RESIDENTIAL' AND tier = 1 THEN 11.81
           WHEN usage_type = 'RESIDENTIAL' AND tier = 2 THEN 11.18
           WHEN usage_type = 'RESIDENTIAL' AND tier = 3 THEN 10.12
           WHEN usage_type = 'RESIDENTIAL' AND tier = 4 THEN 10.17
           WHEN usage_type = 'RESIDENTIAL' AND tier = 5 THEN 10.94
           WHEN usage_type = 'RESIDENTIAL' AND tier = 6 THEN 13.19
           WHEN usage_type = 'COMMERCIAL' THEN 17.90
           WHEN usage_type = 'INDUSTRIAL' THEN 170.50
       END,
       reference_people_count = NULL,
       reference_person_daily_liters = NULL
 WHERE valid_from = DATE '2026-01-01';

UPDATE alert_rate.home_rate
   SET m3_value = CASE
           WHEN usage_type = 'RESIDENTIAL' AND tier = 1 THEN 1560.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 2 THEN 2450.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 3 THEN 3400.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 4 THEN 3900.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 5 THEN 5900.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 6 THEN 6300.00
           WHEN usage_type = 'COMMERCIAL' THEN 5850.00
           WHEN usage_type = 'INDUSTRIAL' THEN 5150.00
       END,
       basic_m3_value = m3_value,
       excess_m3_value = CASE
           WHEN usage_type = 'RESIDENTIAL' AND tier = 1 THEN 5200.00
           WHEN usage_type = 'RESIDENTIAL' AND tier = 2 THEN 4083.33
           WHEN usage_type = 'RESIDENTIAL' AND tier = 3 THEN 4000.00
           ELSE m3_value
       END,
       reference_consumption_m3 = CASE
           WHEN usage_type = 'RESIDENTIAL' AND tier = 1 THEN 11.81
           WHEN usage_type = 'RESIDENTIAL' AND tier = 2 THEN 11.18
           WHEN usage_type = 'RESIDENTIAL' AND tier = 3 THEN 10.12
           WHEN usage_type = 'RESIDENTIAL' AND tier = 4 THEN 10.17
           WHEN usage_type = 'RESIDENTIAL' AND tier = 5 THEN 10.94
           WHEN usage_type = 'RESIDENTIAL' AND tier = 6 THEN 13.19
           WHEN usage_type = 'COMMERCIAL' THEN 17.90
           WHEN usage_type = 'INDUSTRIAL' THEN 170.50
       END,
       updated_at = now()
 WHERE rate_source = 'NATIONAL_FALLBACK';
