-- Solo elimina codigos de semilla que nunca fueron reclamados ni vinculados.
DELETE FROM device.device d
WHERE d.code IN (
    'HS-7A3F91C8D2E4',
    'HS-B6E04D79A153',
    'HS-2C8A5F01E7B9'
)
  AND d.hardware_id IS NULL
  AND NOT EXISTS (
      SELECT 1
      FROM home.home_device hd
      WHERE hd.device_id = d.device_id
  )
  AND NOT EXISTS (
      SELECT 1
      FROM consumption.sensor_reading sr
      WHERE sr.device_id = d.device_id
  );
