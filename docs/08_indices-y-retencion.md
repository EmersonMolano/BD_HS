# Índices, agregados y retención

Los índices se crean principalmente en
[`01_ddl/09_indexes`](../01_ddl/09_indexes), con optimizaciones adicionales en
migraciones posteriores. Su objetivo es acelerar filtros y uniones frecuentes;
cada índice también aumenta el coste de escritura y almacenamiento.

## Grupos principales

- Identidad y preferencias: búsquedas por identificador, estado y claves de
  usuario.
- Hogares y dispositivos: miembros, rol, hogar, estado del vínculo y estado del
  dispositivo.
- Lecturas: `device_id`, `home_id`, `recorded_at DESC`, actividad y la combinación
  hogar/fecha. Migraciones posteriores agregan claves para timestamps y
  deduplicación de ingesta.
- Alertas, soporte y auditoría: estado, hogar/usuario, tipo y fechas recientes.
- Vistas materializadas: claves únicas requeridas para su actualización
  concurrente.

Las definiciones exactas, columnas y predicados parciales están en los SQL de
índices; no crees un duplicado solo porque el nombre cambie.

## Consultar y medir

Usa `EXPLAIN (ANALYZE, BUFFERS)` con una consulta representativa y datos de
tamaño realista. Compara estimaciones, filas leídas, bloques y tiempo antes y
después. `ANALYZE` ejecuta la consulta: úsalo con cuidado en sentencias que
tengan efectos laterales, y nunca conviertas una prueba local en un cambio
productivo sin revisar el plan.

Ejemplo de inspección de lecturas (ajusta las columnas/filtros al endpoint):

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT device_id, recorded_at
FROM consumption.sensor_reading
WHERE home_id = '00000000-0000-0000-0000-000000000000'
  AND recorded_at >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY recorded_at DESC;
```

No mantengas índices que no aporten una mejora demostrable; primero verifica
uso, volumen de escrituras, planes y dependencias.

## Agregación y tareas existentes

El backend actualiza vistas materializadas aproximadamente cada cinco minutos
y ejecuta limpieza de auditoría con retención predeterminada de 365 días y
lotes de hasta 1000 filas. Los procesos periódicos usan advisory locks para
evitar ejecución concurrente entre instancias. Consulta
[guía de jobs del backend](https://github.com/joseamaya009/Backend-Hidrosmart/blob/hu-11-dev/docs/06_mqtt-y-procesos-asincronos.md)
para los valores configurables.

La rutina de archivo de tickets (`analytics_support.prc_archive_closed_tickets`)
existe en DDL, pero no se debe asumir que corre automáticamente: no aparece como
job periódico del backend observado. Asimismo, la limpieza de auditoría no es
una política general de retención para telemetría. En el código revisado no se
identificó una tarea automática de borrado de `sensor_reading`.

## Antes de fijar una política de retención

Define y aprueba por separado retención de telemetría cruda, agregados,
auditoría, tickets y reportes; considera obligaciones legales, recuperación,
coste y necesidades analíticas. Prueba primero en copia restaurable, estima
filas afectadas, usa lotes y registra la operación. No añadas un `DELETE` ni
reduzcas retención en una guía como si ya estuviera desplegado: cualquier
cambio necesita migración, autorización del responsable de datos y prueba de
restauración.
