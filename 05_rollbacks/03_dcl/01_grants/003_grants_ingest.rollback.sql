REVOKE INSERT ON consumption.sensor_reading FROM hidro_smart_ingest;
REVOKE USAGE ON SCHEMA consumption FROM hidro_smart_ingest;
REVOKE CONNECT ON DATABASE postgres FROM hidro_smart_ingest;
