# Base de datos: modelo y migraciones

## Dominios principales

| Esquema | Responsabilidad |
| --- | --- |
| `user_account` | Usuarios, perfiles, sesiones, credenciales y roles funcionales. |
| `home` | Hogares, miembros, invitaciones, metas y vacaciones. |
| `device` | Dispositivos, asociaciones, configuración y estados. |
| `consumption` | Lecturas, agregados y consultas de consumo. |
| `alert_rate` | Umbrales, alertas y tarifas. |
| `analytics_support` | Reportes, recomendaciones y soporte. |
| `audit` | Trazabilidad y errores. |
| `privacy` | Consentimientos y solicitudes de privacidad. |

## Seguridad de datos

- `hidro_smart_app` realiza las operaciones normales del backend.
- `hidro_smart_ingest` se limita a la ingesta MQTT.
- Las operaciones sensibles usan funciones SQL y transacciones con contexto de
  usuario.
- RLS protege recursos que pertenecen a hogares o usuarios.
- Las contraseñas Wi-Fi no se almacenan en PostgreSQL.

## Flujo de cambios

1. Crea un archivo SQL o YAML en la capa correspondiente.
2. Inclúyelo en el changelog de esa capa en orden ascendente.
3. Ejecuta `liquibase validate`, `status --verbose` y `update` en local.
4. Añade, cuando corresponda, una referencia de rollback en `05_rollbacks`.
5. Actualiza pruebas y documentación que cambien por la migración.

## IoT

La telemetría entra a través de una función de ingesta controlada. Debe incluir
un `mqttMessageId` para permitir idempotencia. La asociación activa entre el
dispositivo y el hogar es requisito para aceptar la lectura.

Los códigos lógicos preasignados están en `02_dml/03_upserts`; se usan una vez
por placa y no reemplazan el `hardwareId` físico.

Para backup y recuperación consulta
[../../docs/respaldo-postgresql.md](../../docs/respaldo-postgresql.md).

## Guías detalladas por capa

- [01_ddl: estructura de la base de datos](01_ddl.md). Documenta sus diez
  subcarpetas y cada archivo activo.

- [02_dml: datos iniciales y correcciones](02_dml.md). Cubre catálogos,
  referencias tarifarias, códigos ESP32 preasignados y parches de datos.
- [03_dcl: roles, privilegios y RLS](03_dcl.md). Explica roles técnicos,
  grants y políticas de aislamiento por filas.
- [04_tcl: operaciones manuales](04_tcl.md). Describe mantenimiento,
  recuperación de usuario y etiquetas de versión fuera del despliegue normal.
- [05_rollbacks: reversión controlada](05_rollbacks.md). Cataloga los 194
  scripts de reversión externos y sus precauciones de uso.

## Guías transversales

- [06_modelo-entidad-relacion](06_modelo-entidad-relacion.md): mapa conceptual
  de identidades, hogares, dispositivos, lecturas, alertas y soporte.
- [07_rls-y-seguridad](07_rls-y-seguridad.md): roles técnicos, contexto de
  usuario, aislamiento RLS y pruebas negativas.
- [08_indices-y-retencion](08_indices-y-retencion.md): familias de índices,
  agregados, procesos de limpieza observados y asuntos de retención pendientes.
