DELETE FROM alert_rate.home_rate
 WHERE rate_source = 'NATIONAL_FALLBACK'
   AND valid_from = DATE '2026-01-01';

DELETE FROM alert_rate.reference_rate
 WHERE valid_from = DATE '2026-01-01'
   AND source_note LIKE 'Benchmark nacional HidroSmart%';
