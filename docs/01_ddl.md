# Capa 01_ddl: estructura de la base de datos

01_ddl crea la estructura permanente de PostgreSQL: extensiones, esquemas, tablas, relaciones, vistas materializadas, funciones, procedimientos, triggers e índices. Los datos base pertenecen a 02_dml y los permisos técnicos/RLS a 03_dcl.

El archivo 01_ddl/changelog.yaml define el orden real de Liquibase:

    00_extensions → 01_schemas → 02_types → 03_tables
    → 05_materialized_views → 04_alter → 06_functions
    → 07_procedures → 08_triggers → 09_indexes

Cada 0000changelog.yaml registra los SQL de su carpeta. Si un archivo posterior usa CREATE OR REPLACE, reemplaza la versión previa del mismo objeto. Este documento es el modelo para las futuras guías 02_dml, 03_dcl, 04_tcl y 05_rollbacks.

## 00_extensions: capacidades de PostgreSQL

Activa extensiones requeridas por el modelo.

- 0000changelog.yaml: registra los tres changesets de extensiones.
- 001_enable_btree_gist_extension.sql: activa btree_gist, útil para restricciones de exclusión y comparaciones GiST de valores escalares.
- 001_enable_uuid_extension.sql: activa uuid-ossp, compatible con generadores UUID históricos.
- 002_enable_pgcrypto_extension.sql: activa pgcrypto; habilita gen_random_uuid() para identificadores predeterminados.

## 01_schemas: dominios lógicos

Separa objetos por responsabilidad y permite permisos claros por esquema.

- 0000changelog.yaml: registra los nueve esquemas de negocio.
- 001_schema_user_account.sql: crea user_account para cuentas, credenciales, sesiones, roles y permisos.
- 002_schema_preference.sql: crea preference para idioma, moneda, tema y preferencias.
- 003_schema_home.sql: crea home para hogares, miembros, solicitudes, metas y vacaciones.
- 004_schema_device.sql: crea device para equipos IoT, configuración, estado e historial técnico.
- 005_schema_consumption.sql: crea consumption para lecturas, resúmenes y cálculos de agua.
- 006_schema_alert_rate.sql: crea alert_rate para umbrales, reglas, eventos, notificaciones y tarifas.
- 007_schema_analytics_support.sql: crea analytics_support para reportes, recomendaciones y tickets.
- 008_schema_audit.sql: crea audit para auditoría funcional y errores.
- 009_schema_privacy.sql: crea privacy para consentimientos y solicitudes ARCO.

## 02_types: reserva para tipos personalizados

Actualmente no define tipos SQL; las validaciones usan CHECK, claves foráneas y funciones.

- 0000changelog.yaml: mantiene disponible la capa para cambios futuros.
- .gitkeep: conserva la carpeta vacía en Git.

## 03_tables: tablas base

Primero crea entidades por dominio; las relaciones transversales y ajustes se añaden después en 04_alter.

- 0000changelog.yaml: ejecuta las tablas respetando dependencias.
- 001_Users_authentication.sql: cuentas, perfiles, credenciales, MFA, sesiones, tokens, intentos de acceso, roles y permisos.
- 002_Preferences_personalitation.sql: catálogos de idioma, moneda y tema, más preferencias de usuario.
- 003_Homes_members.sql: hogares, miembros, funciones, solicitudes, vacaciones y metas.
- 004_Iot_devices.sql: dispositivos, historial, calibración, telemetría y relación hogar-dispositivo.
- 005_Consuption_monitoring.sql: lecturas y resúmenes diarios, horarios, mensuales y predicciones.
- 006_Alerts_control.sql: umbrales, reglas, eventos, notificaciones y tarifas.
- 007_Reports_analytics_support.sql: recomendaciones, reportes y soporte.
- 008_Audit_logs.sql: auditoría de acciones y errores técnicos.
- 009_Privacy_arco.sql: consentimientos y solicitudes de privacidad.
- 010_Actuators.sql: actuadores, comandos MQTT y estados reportados.

## 04_alter: relaciones y evolución

Modifica objetos ya creados sin editar changesets aplicados. Los saltos de numeración indican cambios sustituidos o no integrados, no una falla.

- 0000changelog.yaml: registra todas las alteraciones activas.
- 001_fk_user_account.sql: añade relaciones internas de cuentas, roles y credenciales.
- 003_fk_home.sql: conecta miembros, funciones y solicitudes de hogares.
- 004_fk_device.sql: conecta historial, calibración y asociaciones de equipos.
- 006_fk_alert_rate.sql: conecta umbrales y reglas con hogares y dependencias.
- 007_fk_analytics_support.sql: conecta recomendaciones, reportes y tickets.
- 009_fk_privacy.sql: conecta consentimientos y solicitudes con usuarios.
- 010_srs_alignment.sql: ajusta perfiles y restricciones a requisitos funcionales.
- 011_integrity_and_archive.sql: refuerza integridad y archivado de tickets y lecturas históricas.
- 012_remove_duplicate_inline_fks.sql: retira claves foráneas duplicadas.
- 013_mfa_protection.sql: endurece restricciones de MFA.
- 014_retain_history_and_tickets.sql: ajusta retención de consumo, resúmenes y tickets cerrados.
- 016_device_status_integrity.sql: valida el estado operativo del dispositivo.
- 017_privacy_retention_and_tier_fks.sql: añade retención de privacidad y relaciones para niveles/tarifas.
- 018_ticket_assignment.sql: incorpora asignación de tickets e índice asociado.
- 019_document_number_max_10.sql: normaliza el tamaño de documento del perfil.
- 020_alert_rule_units_and_event_dedup.sql: añade unidades a reglas y deduplicación de alertas.
- 021_iot_sensor_reading_ingest.sql: prepara lecturas para ingesta IoT controlada e idempotente.
- 022_device_ingest_hardening.sql: endurece datos de dispositivos y telemetría MQTT.
- 023_actuator_command_validation.sql: valida comandos dirigidos a actuadores.
- 024_email_verification_pending.sql: incorpora cuentas pendientes de verificación por correo.
- 025_profile_avatar.sql: añade avatar opcional al perfil.
- 026_profile_phone_max_60.sql: amplía y valida teléfono hasta 60 caracteres.
- 027_consumption_precision.sql: aumenta precisión de consumo y costos.
- 028_device_location.sql: añade ubicación funcional al dispositivo.
- 029_device_provisioning.sql: añade estado de aprovisionamiento BLE/Wi-Fi/MQTT.
- 030_device_wifi_metadata.sql: guarda SSID e IP reportados, nunca contraseña Wi-Fi.
- 031_home_usage_and_billing_reference.sql: añade referencias de uso y facturación por hogar.
- 032_home_mini_reference_profile.sql: ajusta el perfil simplificado de hogar.
- 033_validate_iot_metric_constraints.sql: valida rangos y consistencia de métricas IoT.

## 05_materialized_views: consultas precalculadas

Mejoran dashboard, alertas y reportes; se refrescan mediante procedimientos y jobs.

- 0000changelog.yaml: registra las vistas materializadas.
- .gitkeep: conserva la carpeta en Git.
- 001_mv_home_monthly_consumption.sql: resumen mensual inicial por hogar.
- 002_mv_pending_alerts.sql: alertas pendientes agrupadas por hogar.
- 003_mv_active_devices.sql: dispositivos activos y estado por hogar.
- 004_mv_recommendation_summary.sql: resumen de recomendaciones por hogar.
- 005_mv_hourly_consumption_avg.sql: agregado horario promedio de consumo.
- 006_mv_hourly_consumption_by_home.sql: ajusta el agregado horario para incluir correctamente el hogar.
- 007_mv_home_monthly_all_history.sql: amplía el resumen mensual a todo el historial.

## 06_functions: reglas de negocio SQL

Estas funciones concentran operaciones sensibles, validaciones y consultas que el backend no debe repetir con SQL ad hoc.

- 0000changelog.yaml: ejecuta funciones en orden de evolución.
- .gitkeep: conserva la carpeta en Git.
- 001_fn_security_helpers.sql: obtiene el usuario de aplicación y comprueba membresía de hogar.
- 002_fn_consumption_calculations.sql: introduce cálculos de consumo y costo.
- 003_fn_alert_validation.sql: comprueba umbrales y posibles fugas.
- 004_fn_vacation_helpers.sql: determina vacaciones activas de un hogar.
- 005_fn_analytics_helpers.sql: calcula progreso de metas.
- 006_fn_home_creation.sql: crea un hogar y su Owner de forma atómica.
- 007_fn_cost_business_rules.sql: ajusta reglas de cálculo de costo.
- 008_fn_user_registration.sql: introduce el registro básico de usuario.
- 009_fn_rls_status_checks.sql: define ayudantes RLS y acceso a dispositivos.
- 010_fn_period_cost.sql: calcula costo acumulado por período.
- 011_fn_login_attempts.sql: registra y reinicia intentos de login.
- 012_fn_registration_normalization.sql: normaliza el registro de usuario.
- 013_fn_login_attempts_validation.sql: endurece validación de intentos fallidos.
- 014_fn_sensitive_auth.sql: protege lectura de credenciales, hashes y MFA.
- 015_fn_rbac.sql: verifica permisos funcionales de un usuario.
- 016_fn_secure_materialized_views.sql: consulta vistas materializadas según permisos.
- 017_optimize_date_queries.sql: optimiza consultas y cálculos por fecha.
- 018_fn_registration_flows.sql: completa registro con rol predeterminado.
- 019_fn_device_management.sql: valida gestión de dispositivos por hogar.
- 020_fn_scoped_calculations.sql: exige contexto autorizado para cálculos.
- 021_fn_ingest_validation.sql: valida si un dispositivo puede ingresar una lectura IoT.
- 022_fn_home_member_management.sql: agrega miembros autorizadamente.
- 023_fn_change_home_member_role.sql: cambia un rol dentro del hogar.
- 024_fn_remove_home_member.sql: elimina miembros respetando invariantes.
- 025_fn_request_home_membership.sql: crea y responde solicitudes de ingreso.
- 026_fn_update_device_status.sql: actualiza estado operativo de dispositivo.
- 027_fn_session_tokens.sql: crea, rota y revoca sesiones/refresh tokens.
- 028_fn_fix_session_rotation.sql: corrige la rotación de refresh tokens.
- 029_fn_password_operations.sql: cambio y recuperación segura de contraseña.
- 030_fn_auth_security_and_device_visibility.sql: estado de login y visibilidad de dispositivos.
- 031_fn_timezone_policy_alignment.sql: alinea políticas con zona horaria.
- 032_fn_active_password_policy.sql: obtiene la política de contraseña activa.
- 033_fn_generate_alert_events.sql: genera alertas para una fecha objetivo.
- 034_fn_role_management.sql: lista, asigna y retira roles globales.
- 035_fn_generate_alert_events_no_reading.sql: agrega alertas por ausencia de lecturas.
- 036_fn_list_audit_logs.sql: lista auditoría con filtros y paginación.
- 037_fn_generate_alert_events_consistent.sql: hace idempotente la generación de alertas.
- 038_fn_authorization_context.sql: expone contexto de autorización para API/RLS.
- 039_fn_bootstrap_first_administrator.sql: crea el primer Administrator seguro.
- 040_fn_auth_and_iot_ingest.sql: integra verificación de correo e ingesta IoT.
- 041_fn_auth_hardening.sql: endurece contexto y revocación de sesiones.
- 042_fn_iot_ingest_returning_fix.sql: corrige retorno de ingesta de sensor.
- 043_fn_iot_ingest_metrics_and_timestamps.sql: añade métricas y timestamps a la ingesta.
- 044_fn_device_status_ingest.sql: registra estados MQTT de dispositivos.
- 045_fn_session_management.sql: lista y revoca sesiones propias.
- 046_fn_account_lifecycle.sql: cambia estado y elimina cuentas controladamente.
- 047_fn_list_managed_users.sql: lista usuarios administrables.
- 048_fn_get_password_reset_email.sql: obtiene correo por token de recuperación.
- 049_fn_actuator_status.sql: registra estado y ACK de actuadores.
- 050_fn_timeout_actuator_commands.sql: vence comandos sin respuesta.
- 051_fn_registration_email_verification.sql: consume tokens de verificación.
- 052_fn_consumption_precision.sql: deja cálculos con precisión final.
- 053_fn_device_registration_and_linking.sql: registra y vincula dispositivos.
- 054_fn_consumption_series.sql: devuelve series para dashboard y reportes.
- 055_fn_claim_provisioned_device.sql: reclama dispositivo por identidad reportada.
- 056_fn_home_billing_profile.sql: crea hogar con perfil de facturación.
- 057_fn_billing_cost_logic.sql: aplica límites y reglas de costo facturable.
- 058_fn_home_people_profile.sql: añade cantidad de personas al hogar.
- 059_fn_mini_cost_and_budget_logic.sql: simplifica costo y estado de presupuesto.
- 060_fn_managed_user_overview.sql: devuelve resumen administrativo de usuario.
- 061_fn_list_home_members.sql: lista miembros según permisos del solicitante.
- 062_fn_link_device_to_home_by_hardware.sql: vincula por hardwareId.
- 063_fn_delete_unlinked_device.sql: elimina solo dispositivos sin hogar.

## 07_procedures: tareas de operación

Los procedimientos se llaman desde jobs del backend o mantenimiento.

- 0000changelog.yaml: registra los procedimientos.
- .gitkeep: conserva la carpeta en Git.
- 001_prc_refresh_materialized_views.sql: introduce refresco de vistas.
- 002_prc_generate_daily_summary.sql: genera resumen diario de consumo.
- 003_prc_clean_old_audit_logs.sql: limpia auditoría fuera de retención.
- 004_prc_archive_closed_tickets.sql: archiva tickets cerrados antiguos.
- 005_prc_generate_daily_summary_optimized.sql: optimiza resumen diario.
- 006_prc_refresh_materialized_views_concurrent.sql: usa refresco concurrente cuando es posible.
- 007_prc_clean_old_audit_logs_fixed.sql: corrige limpieza y parámetros de logs.

## 08_triggers: automatización por eventos

Los triggers reaccionan a inserciones o actualizaciones. Las versiones 007, 009 y 010 evolucionan la lógica posterior a una lectura; la última queda vigente.

- 0000changelog.yaml: registra triggers y funciones auxiliares.
- .gitkeep: conserva la carpeta en Git.
- 001_trg_update_updated_at.sql: actualiza campos updated_at automáticamente.
- 002_trg_audit_user_account.sql: audita cambios de cuenta.
- 003_trg_after_reading_insert.sql: introduce acciones tras insertar lectura.
- 004_trg_after_alert_insert.sql: define manejador posterior a alertas.
- 005_trg_after_reading_update_mv.sql: actualiza datos derivados al modificar una lectura.
- 006_trg_home_owner_invariant.sql: garantiza al menos un Owner por hogar.
- 007_trg_after_reading_insert_optimized.sql: optimiza alertas tras lectura.
- 008_trg_device_status_change.sql: registra fecha de cambio de estado del dispositivo.
- 009_trg_after_reading_alert_periods.sql: añade alertas diaria y mensual.
- 010_trg_after_reading_alert_consistency.sql: deja alertas consistentes e idempotentes.
- 011_trg_sensor_reading_cost.sql: calcula costo estimado con la tarifa vigente.

## 09_indexes: rendimiento e integridad

Los índices aceleran filtros y relaciones; los únicos impiden duplicados funcionales.

- 0000changelog.yaml: registra índices después de crear los objetos.
- .gitkeep: conserva la carpeta en Git.
- 001_idx_user_account.sql: cuentas, perfiles, credenciales, roles y sesiones.
- 002_idx_preference.sql: catálogos y preferencias de usuario.
- 003_idx_home.sql: hogares, miembros, solicitudes, vacaciones y metas.
- 004_idx_device.sql: código, estado, historial, calibración y telemetría.
- 005_idx_consumption.sql: lecturas y resúmenes por hogar, fecha y período.
- 006_idx_alert_rate.sql: umbrales, reglas, eventos, notificaciones y tarifas.
- 007_idx_analytics_support.sql: recomendaciones, reportes y soporte.
- 008_idx_audit.sql: auditoría y errores por usuario, fecha, acción o severidad.
- 009_idx_privacy.sql: consentimientos y solicitudes ARCO.
- 010_idx_case_insensitive_identity.sql: unicidad de username/email sin distinguir mayúsculas.
- 011_integrity_dedup.sql: evita solicitudes, reglas y alertas duplicadas.
- 012_mv_concurrent_refresh_keys.sql: claves únicas para refresco concurrente de vistas.
- 013_alert_event_dedup.sql: impide alertas repetidas con misma regla, hogar y clave.

## Cómo usar esta guía

1. Empieza por changelog.yaml para conocer el orden efectivo.
2. Revisa 01_schemas y 03_tables para entender el modelo base.
3. Consulta 04_alter antes de asumir que una tabla solo tiene sus columnas originales.
4. Busca una función, procedimiento o trigger antes de añadir SQL desde backend.
5. Revisa 09_indexes antes de crear índices nuevos.
