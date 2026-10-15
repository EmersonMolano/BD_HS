# 05_rollbacks: reversión controlada de migraciones

## Propósito

05_rollbacks reúne archivos SQL que revierten cambios concretos de las capas
01_ddl, 02_dml y 03_dcl. Es un catálogo de reversas; no es una migración que
Liquibase ejecute por sí sola.

La carpeta no tiene changelog raíz ni está incluida por
BD_HS/changelog-master.yaml. Los rollbacks que Liquibase puede invocar están
referenciados desde los 0000changelog.yaml de la capa original. Algunos
changesets usan rollback en línea y otros no tienen rollback externo.

## Reglas de uso

1. Identifica el changeset original y confirma en DATABASECHANGELOG que fue
   aplicado.
2. Haz backup verificable antes de revertir DDL, DML o permisos.
3. Revisa dependencias de objetos, datos y servicios antes de ejecutar el SQL.
4. Aplica cambios dependientes en orden inverso al de su instalación.
5. Prueba backend, MQTT, roles y RLS después de la reversión.
6. No ejecutes toda esta carpeta de forma masiva: cada archivo revierte una
   pieza específica y puede no ser seguro fuera de su contexto.

## Cobertura

Hay 194 scripts de rollback externos. Que un changeset no aparezca
aquí no significa necesariamente que no tenga reversión: puede tenerla escrita
en línea en su changelog. Si no existe ni rollback externo ni rollback en línea,
la migración requiere un plan manual antes de revertirse.

## Archivos por capa y subcarpeta

### 01_ddl / 00_extensions

Revierte la habilitación de extensiones de PostgreSQL. Desinstalar una extensión puede fallar o afectar objetos que todavía dependen de ella; se requiere revisar dependencias antes de ejecutarlo.

- **001_enable_btree_gist_extension.rollback.sql:** revierte el changeset enable btree gist extension de 01_ddl/00_extensions.
- **001_enable_uuid_extension.rollback.sql:** revierte el changeset enable uuid extension de 01_ddl/00_extensions.
- **002_enable_pgcrypto_extension.rollback.sql:** revierte el changeset enable pgcrypto extension de 01_ddl/00_extensions.

### 01_ddl / 01_schemas

Revierte la creación de esquemas de dominio. Estos scripts son potencialmente destructivos si el esquema contiene objetos o datos.

- **001_schema_user_account.rollback.sql:** revierte el changeset schema user account de 01_ddl/01_schemas.
- **002_schema_preference.rollback.sql:** revierte el changeset schema preference de 01_ddl/01_schemas.
- **003_schema_home.rollback.sql:** revierte el changeset schema home de 01_ddl/01_schemas.
- **004_schema_device.rollback.sql:** revierte el changeset schema device de 01_ddl/01_schemas.
- **005_schema_consumption.rollback.sql:** revierte el changeset schema consumption de 01_ddl/01_schemas.
- **006_schema_alert_rate.rollback.sql:** revierte el changeset schema alert rate de 01_ddl/01_schemas.
- **007_schema_analytics_support.rollback.sql:** revierte el changeset schema analytics support de 01_ddl/01_schemas.
- **008_schema_audit.rollback.sql:** revierte el changeset schema audit de 01_ddl/01_schemas.
- **009_schema_privacy.rollback.sql:** revierte el changeset schema privacy de 01_ddl/01_schemas.

### 01_ddl / 03_tables

Revierte tablas de cada dominio. Requiere backup y análisis de dependencias porque puede eliminar estructura y datos.

- **001_Users_authentication.rollback.sql:** revierte el changeset Users authentication de 01_ddl/03_tables.
- **002_Preferences_personalitation.rollback.sql:** revierte el changeset Preferences personalitation de 01_ddl/03_tables.
- **003_Homes_members.rollback.sql:** revierte el changeset Homes members de 01_ddl/03_tables.
- **004_Iot_devices.rollback.sql:** revierte el changeset Iot devices de 01_ddl/03_tables.
- **005_Consuption_monitoring.rollback.sql:** revierte el changeset Consuption monitoring de 01_ddl/03_tables.
- **006_Alerts_control.rollback.sql:** revierte el changeset Alerts control de 01_ddl/03_tables.
- **007_Reports_analytics_support.rollback.sql:** revierte el changeset Reports analytics support de 01_ddl/03_tables.
- **008_Audit_logs.rollback.sql:** revierte el changeset Audit logs de 01_ddl/03_tables.
- **009_Privacy_arco.rollback.sql:** revierte el changeset Privacy arco de 01_ddl/03_tables.
- **010_Actuators.rollback.sql:** revierte el changeset Actuators de 01_ddl/03_tables.

### 01_ddl / 04_alter

Revierte restricciones, columnas, reglas de integridad o metadatos añadidos posteriormente. Debe aplicarse en orden inverso al de la migración.

- **001_fk_user_account.rollback.sql:** revierte el changeset fk user account de 01_ddl/04_alter.
- **003_fk_home.rollback.sql:** revierte el changeset fk home de 01_ddl/04_alter.
- **004_fk_device.rollback.sql:** revierte el changeset fk device de 01_ddl/04_alter.
- **006_fk_alert_rate.rollback.sql:** revierte el changeset fk alert rate de 01_ddl/04_alter.
- **007_fk_analytics_support.rollback.sql:** revierte el changeset fk analytics support de 01_ddl/04_alter.
- **009_fk_privacy.rollback.sql:** revierte el changeset fk privacy de 01_ddl/04_alter.
- **013_mfa_protection.rollback.sql:** revierte el changeset mfa protection de 01_ddl/04_alter.
- **014_retain_history_and_tickets.rollback.sql:** revierte el changeset retain history and tickets de 01_ddl/04_alter.
- **016_device_status_integrity.rollback.sql:** revierte el changeset device status integrity de 01_ddl/04_alter.
- **017_privacy_retention_and_tier_fks.rollback.sql:** revierte el changeset privacy retention and tier fks de 01_ddl/04_alter.
- **018_ticket_assignment.rollback.sql:** revierte el changeset ticket assignment de 01_ddl/04_alter.
- **019_document_number_max_10.rollback.sql:** revierte el changeset document number max 10 de 01_ddl/04_alter.
- **020_alert_rule_units_and_event_dedup.rollback.sql:** revierte el changeset alert rule units and event dedup de 01_ddl/04_alter.
- **021_iot_sensor_reading_ingest.rollback.sql:** revierte el changeset iot sensor reading ingest de 01_ddl/04_alter.
- **022_device_ingest_hardening.rollback.sql:** revierte el changeset device ingest hardening de 01_ddl/04_alter.
- **023_actuator_command_validation.rollback.sql:** revierte el changeset actuator command validation de 01_ddl/04_alter.
- **024_email_verification_pending.rollback.sql:** revierte el changeset email verification pending de 01_ddl/04_alter.
- **025_profile_avatar.rollback.sql:** revierte el changeset profile avatar de 01_ddl/04_alter.
- **026_profile_phone_max_60.rollback.sql:** revierte el changeset profile phone max 60 de 01_ddl/04_alter.
- **027_consumption_precision.rollback.sql:** revierte el changeset consumption precision de 01_ddl/04_alter.
- **028_device_location.rollback.sql:** revierte el changeset device location de 01_ddl/04_alter.
- **029_device_provisioning.rollback.sql:** revierte el changeset device provisioning de 01_ddl/04_alter.
- **030_device_wifi_metadata.rollback.sql:** revierte el changeset device wifi metadata de 01_ddl/04_alter.
- **031_home_usage_and_billing_reference.rollback.sql:** revierte el changeset home usage and billing reference de 01_ddl/04_alter.
- **032_home_mini_reference_profile.rollback.sql:** revierte el changeset home mini reference profile de 01_ddl/04_alter.
- **033_validate_iot_metric_constraints.rollback.sql:** revierte el changeset validate iot metric constraints de 01_ddl/04_alter.

### 01_ddl / 05_materialized_views

Revierte el cambio asociado a la vista materializada indicada. Verifica que los reportes no la estén usando.

- **007_mv_home_monthly_all_history.rollback.sql:** revierte el changeset mv home monthly all history de 01_ddl/05_materialized_views.

### 01_ddl / 06_functions

Revierte versiones de funciones de negocio, seguridad, IoT y consumo. El backend y las políticas RLS pueden depender de sus firmas.

- **007_fn_cost_business_rules.rollback.sql:** revierte el changeset fn cost business rules de 01_ddl/06_functions.
- **009_fn_rls_status_checks.rollback.sql:** revierte el changeset fn rls status checks de 01_ddl/06_functions.
- **010_fn_period_cost.rollback.sql:** revierte el changeset fn period cost de 01_ddl/06_functions.
- **011_fn_login_attempts.rollback.sql:** revierte el changeset fn login attempts de 01_ddl/06_functions.
- **012_fn_registration_normalization.rollback.sql:** revierte el changeset fn registration normalization de 01_ddl/06_functions.
- **013_fn_login_attempts_validation.rollback.sql:** revierte el changeset fn login attempts validation de 01_ddl/06_functions.
- **014_fn_sensitive_auth.rollback.sql:** revierte el changeset fn sensitive auth de 01_ddl/06_functions.
- **015_fn_rbac.rollback.sql:** revierte el changeset fn rbac de 01_ddl/06_functions.
- **016_fn_secure_materialized_views.rollback.sql:** revierte el changeset fn secure materialized views de 01_ddl/06_functions.
- **017_optimize_date_queries.rollback.sql:** revierte el changeset optimize date queries de 01_ddl/06_functions.
- **018_fn_registration_flows.rollback.sql:** revierte el changeset fn registration flows de 01_ddl/06_functions.
- **019_fn_device_management.rollback.sql:** revierte el changeset fn device management de 01_ddl/06_functions.
- **020_fn_scoped_calculations.rollback.sql:** revierte el changeset fn scoped calculations de 01_ddl/06_functions.
- **021_fn_ingest_validation.rollback.sql:** revierte el changeset fn ingest validation de 01_ddl/06_functions.
- **022_fn_home_member_management.rollback.sql:** revierte el changeset fn home member management de 01_ddl/06_functions.
- **023_fn_change_home_member_role.rollback.sql:** revierte el changeset fn change home member role de 01_ddl/06_functions.
- **024_fn_remove_home_member.rollback.sql:** revierte el changeset fn remove home member de 01_ddl/06_functions.
- **025_fn_request_home_membership.rollback.sql:** revierte el changeset fn request home membership de 01_ddl/06_functions.
- **026_fn_update_device_status.rollback.sql:** revierte el changeset fn update device status de 01_ddl/06_functions.
- **027_fn_session_tokens.rollback.sql:** revierte el changeset fn session tokens de 01_ddl/06_functions.
- **028_fn_fix_session_rotation.rollback.sql:** revierte el changeset fn fix session rotation de 01_ddl/06_functions.
- **029_fn_password_operations.rollback.sql:** revierte el changeset fn password operations de 01_ddl/06_functions.
- **030_fn_auth_security_and_device_visibility.rollback.sql:** revierte el changeset fn auth security and device visibility de 01_ddl/06_functions.
- **031_fn_timezone_policy_alignment.rollback.sql:** revierte el changeset fn timezone policy alignment de 01_ddl/06_functions.
- **032_fn_active_password_policy.rollback.sql:** revierte el changeset fn active password policy de 01_ddl/06_functions.
- **033_fn_generate_alert_events.rollback.sql:** revierte el changeset fn generate alert events de 01_ddl/06_functions.
- **034_fn_role_management.rollback.sql:** revierte el changeset fn role management de 01_ddl/06_functions.
- **036_fn_list_audit_logs.rollback.sql:** revierte el changeset fn list audit logs de 01_ddl/06_functions.
- **040_fn_auth_and_iot_ingest.rollback.sql:** revierte el changeset fn auth and iot ingest de 01_ddl/06_functions.
- **041_fn_auth_hardening.rollback.sql:** revierte el changeset fn auth hardening de 01_ddl/06_functions.
- **042_fn_iot_ingest_returning_fix.rollback.sql:** revierte el changeset fn iot ingest returning fix de 01_ddl/06_functions.
- **043_fn_iot_ingest_metrics_and_timestamps.rollback.sql:** revierte el changeset fn iot ingest metrics and timestamps de 01_ddl/06_functions.
- **044_fn_device_status_ingest.rollback.sql:** revierte el changeset fn device status ingest de 01_ddl/06_functions.
- **045_fn_session_management.rollback.sql:** revierte el changeset fn session management de 01_ddl/06_functions.
- **046_fn_account_lifecycle.rollback.sql:** revierte el changeset fn account lifecycle de 01_ddl/06_functions.
- **047_fn_list_managed_users.rollback.sql:** revierte el changeset fn list managed users de 01_ddl/06_functions.
- **048_fn_get_password_reset_email.rollback.sql:** revierte el changeset fn get password reset email de 01_ddl/06_functions.
- **049_fn_actuator_status.rollback.sql:** revierte el changeset fn actuator status de 01_ddl/06_functions.
- **050_fn_timeout_actuator_commands.rollback.sql:** revierte el changeset fn timeout actuator commands de 01_ddl/06_functions.
- **051_fn_registration_email_verification.rollback.sql:** revierte el changeset fn registration email verification de 01_ddl/06_functions.
- **052_fn_consumption_precision.rollback.sql:** revierte el changeset fn consumption precision de 01_ddl/06_functions.
- **053_fn_device_registration_and_linking.rollback.sql:** revierte el changeset fn device registration and linking de 01_ddl/06_functions.
- **054_fn_consumption_series.rollback.sql:** revierte el changeset fn consumption series de 01_ddl/06_functions.
- **055_fn_claim_provisioned_device.rollback.sql:** revierte el changeset fn claim provisioned device de 01_ddl/06_functions.
- **056_fn_home_billing_profile.rollback.sql:** revierte el changeset fn home billing profile de 01_ddl/06_functions.
- **057_fn_billing_cost_logic.rollback.sql:** revierte el changeset fn billing cost logic de 01_ddl/06_functions.
- **058_fn_home_people_profile.rollback.sql:** revierte el changeset fn home people profile de 01_ddl/06_functions.
- **059_fn_mini_cost_and_budget_logic.rollback.sql:** revierte el changeset fn mini cost and budget logic de 01_ddl/06_functions.
- **060_fn_managed_user_overview.rollback.sql:** revierte el changeset fn managed user overview de 01_ddl/06_functions.
- **062_fn_link_device_to_home_by_hardware.rollback.sql:** revierte el changeset fn link device to home by hardware de 01_ddl/06_functions.
- **063_fn_delete_unlinked_device.rollback.sql:** revierte el changeset fn delete unlinked device de 01_ddl/06_functions.

### 01_ddl / 07_procedures

Revierte procedimientos de mantenimiento y actualización de agregados. Programa la operación para evitar lecturas inconsistentes.

- **005_prc_generate_daily_summary_optimized.rollback.sql:** revierte el changeset prc generate daily summary optimized de 01_ddl/07_procedures.
- **006_prc_refresh_materialized_views_concurrent.rollback.sql:** revierte el changeset prc refresh materialized views concurrent de 01_ddl/07_procedures.

### 01_ddl / 08_triggers

Revierte triggers de invariantes, telemetría, alertas y costos. Antes de retirarlos, valida los efectos sobre las escrituras futuras.

- **006_trg_home_owner_invariant.rollback.sql:** revierte el changeset trg home owner invariant de 01_ddl/08_triggers.
- **007_trg_after_reading_insert_optimized.rollback.sql:** revierte el changeset trg after reading insert optimized de 01_ddl/08_triggers.
- **008_trg_device_status_change.rollback.sql:** revierte el changeset trg device status change de 01_ddl/08_triggers.
- **009_trg_after_reading_alert_periods.rollback.sql:** revierte el changeset trg after reading alert periods de 01_ddl/08_triggers.
- **011_trg_sensor_reading_cost.rollback.sql:** revierte el changeset trg sensor reading cost de 01_ddl/08_triggers.

### 01_ddl / 09_indexes

Revierte índices y claves de soporte. Puede degradar rendimiento o eliminar controles de unicidad y deduplicación.

- **001_idx_user_account.rollback.sql:** revierte el changeset idx user account de 01_ddl/09_indexes.
- **002_idx_preference.rollback.sql:** revierte el changeset idx preference de 01_ddl/09_indexes.
- **003_idx_home.rollback.sql:** revierte el changeset idx home de 01_ddl/09_indexes.
- **004_idx_device.rollback.sql:** revierte el changeset idx device de 01_ddl/09_indexes.
- **005_idx_consumption.rollback.sql:** revierte el changeset idx consumption de 01_ddl/09_indexes.
- **006_idx_alert_rate.rollback.sql:** revierte el changeset idx alert rate de 01_ddl/09_indexes.
- **007_idx_analytics_support.rollback.sql:** revierte el changeset idx analytics support de 01_ddl/09_indexes.
- **008_idx_audit.rollback.sql:** revierte el changeset idx audit de 01_ddl/09_indexes.
- **009_idx_privacy.rollback.sql:** revierte el changeset idx privacy de 01_ddl/09_indexes.
- **010_idx_case_insensitive_identity.rollback.sql:** revierte el changeset idx case insensitive identity de 01_ddl/09_indexes.
- **011_integrity_dedup.rollback.sql:** revierte el changeset integrity dedup de 01_ddl/09_indexes.
- **012_mv_concurrent_refresh_keys.rollback.sql:** revierte el changeset mv concurrent refresh keys de 01_ddl/09_indexes.
- **013_alert_event_dedup.rollback.sql:** revierte el changeset alert event dedup de 01_ddl/09_indexes.

### 02_dml / 00_inserts

Revierte datos iniciales de permisos y referencias tarifarias. Comprueba que ninguna cuenta u hogar esté usando esos datos antes de retirarlos.

- **010_rbac_permissions.rollback.sql:** revierte el changeset rbac permissions de 02_dml/00_inserts.
- **011_home_billing_references.rollback.sql:** revierte el changeset home billing references de 02_dml/00_inserts.
- **012_home_billing_reference_excess_fix.rollback.sql:** revierte el changeset home billing reference excess fix de 02_dml/00_inserts.
- **013_hidrosmart_mini_defaults.rollback.sql:** revierte el changeset hidrosmart mini defaults de 02_dml/00_inserts.

### 02_dml / 03_upserts

Revierte los códigos lógicos ESP32 preasignados. No debe ejecutarse si alguno ya fue reclamado o está vinculado a un hogar.

- **001_preassigned_esp32_device_codes.rollback.sql:** revierte el changeset preassigned esp32 device codes de 02_dml/03_upserts.

### 02_dml / 04_patches

Revierte correcciones históricas de auditoría, permisos y roles. Hazlo solo para regresar a un estado de migración previo y probado.

- **001_fix_user_account_delete_audit_trigger.rollback.sql:** revierte el changeset fix user account delete audit trigger de 02_dml/04_patches.
- **002_fix_self_delete_audit.rollback.sql:** revierte el changeset fix self delete audit de 02_dml/04_patches.
- **003_audit_event_semantics.rollback.sql:** revierte el changeset audit event semantics de 02_dml/04_patches.
- **004_homeuser_device_permission.rollback.sql:** revierte el changeset homeuser device permission de 02_dml/04_patches.
- **005_actuators_permission.rollback.sql:** revierte el changeset actuators permission de 02_dml/04_patches.
- **006_remove_support_role.rollback.sql:** revierte el changeset remove support role de 02_dml/04_patches.

### 03_dcl / 00_roles

Revierte roles técnicos o su configuración de zona horaria. No debe aplicarse mientras existan conexiones activas o privilegios dependientes.

- **001_create_roles.rollback.sql:** revierte el changeset create roles de 03_dcl/00_roles.
- **003_role_timezone_defaults.rollback.sql:** revierte el changeset role timezone defaults de 03_dcl/00_roles.

### 03_dcl / 01_grants

Revierte grants y hardening de privilegios. Revisa el impacto: retirar EXECUTE o SELECT puede impedir que backend, MQTT o reportes funcionen.

- **002_grants_materialized_views.rollback.sql:** revierte el changeset grants materialized views de 03_dcl/01_grants.
- **003_grants_ingest.rollback.sql:** revierte el changeset grants ingest de 03_dcl/01_grants.
- **007_grant_login_security.rollback.sql:** revierte el changeset grant login security de 03_dcl/01_grants.
- **008_grant_least_privilege_auth_rbac.rollback.sql:** revierte el changeset grant least privilege auth rbac de 03_dcl/01_grants.
- **009_fn_cost_rollback_guard.rollback.sql:** revierte el changeset fn cost rollback guard de 03_dcl/01_grants.
- **010_revoke_sensitive_token_crud.rollback.sql:** revierte el changeset revoke sensitive token crud de 03_dcl/01_grants.
- **011_grant_app_table_privileges.rollback.sql:** revierte el changeset grant app table privileges de 03_dcl/01_grants.
- **012_grant_registration_flows.rollback.sql:** revierte el changeset grant registration flows de 03_dcl/01_grants.
- **013_grant_device_management.rollback.sql:** revierte el changeset grant device management de 03_dcl/01_grants.
- **014_readonly_reporting_privileges.rollback.sql:** revierte el changeset readonly reporting privileges de 03_dcl/01_grants.
- **015_revoke_public_security_definers.rollback.sql:** revierte el changeset revoke public security definers de 03_dcl/01_grants.
- **016_restrict_privacy_table_writes.rollback.sql:** revierte el changeset restrict privacy table writes de 03_dcl/01_grants.
- **017_revoke_scope_helpers_public.rollback.sql:** revierte el changeset revoke scope helpers public de 03_dcl/01_grants.
- **018_secure_mv_access.rollback.sql:** revierte el changeset secure mv access de 03_dcl/01_grants.
- **019_grant_ingest_references.rollback.sql:** revierte el changeset grant ingest references de 03_dcl/01_grants.
- **020_ingest_minimum_privileges.rollback.sql:** revierte el changeset ingest minimum privileges de 03_dcl/01_grants.
- **021_device_history_insert.rollback.sql:** revierte el changeset device history insert de 03_dcl/01_grants.
- **022_device_status_update_function.rollback.sql:** revierte el changeset device status update function de 03_dcl/01_grants.
- **023_session_token_functions.rollback.sql:** revierte el changeset session token functions de 03_dcl/01_grants.
- **024_password_functions.rollback.sql:** revierte el changeset password functions de 03_dcl/01_grants.
- **025_auth_security_function.rollback.sql:** revierte el changeset auth security function de 03_dcl/01_grants.
- **026_active_password_policy_function.rollback.sql:** revierte el changeset active password policy function de 03_dcl/01_grants.
- **027_alert_generation_function.rollback.sql:** revierte el changeset alert generation function de 03_dcl/01_grants.
- **028_role_management_functions.rollback.sql:** revierte el changeset role management functions de 03_dcl/01_grants.
- **030_audit_read_function.rollback.sql:** revierte el changeset audit read function de 03_dcl/01_grants.
- **031_authorization_context_function.rollback.sql:** revierte el changeset authorization context function de 03_dcl/01_grants.
- **032_final_security_hardening.rollback.sql:** revierte el changeset final security hardening de 03_dcl/01_grants.
- **033_auth_and_iot_functions.rollback.sql:** revierte el changeset auth and iot functions de 03_dcl/01_grants.
- **034_auth_hardening_functions.rollback.sql:** revierte el changeset auth hardening functions de 03_dcl/01_grants.
- **035_iot_ingest_metrics_function.rollback.sql:** revierte el changeset iot ingest metrics function de 03_dcl/01_grants.
- **036_device_status_ingest_function.rollback.sql:** revierte el changeset device status ingest function de 03_dcl/01_grants.
- **037_session_management_functions.rollback.sql:** revierte el changeset session management functions de 03_dcl/01_grants.
- **038_account_lifecycle_functions.rollback.sql:** revierte el changeset account lifecycle functions de 03_dcl/01_grants.
- **039_list_managed_users_function.rollback.sql:** revierte el changeset list managed users function de 03_dcl/01_grants.
- **040_telemetry_ingest_function.rollback.sql:** revierte el changeset telemetry ingest function de 03_dcl/01_grants.
- **041_revoke_ingest_direct_insert.rollback.sql:** revierte el changeset revoke ingest direct insert de 03_dcl/01_grants.
- **042_password_reset_context.rollback.sql:** revierte el changeset password reset context de 03_dcl/01_grants.
- **043_actuator_command.rollback.sql:** revierte el changeset actuator command de 03_dcl/01_grants.
- **044_actuator_timeout.rollback.sql:** revierte el changeset actuator timeout de 03_dcl/01_grants.
- **045_device_registration_and_linking.rollback.sql:** revierte el changeset device registration and linking de 03_dcl/01_grants.
- **046_consumption_series.rollback.sql:** revierte el changeset consumption series de 03_dcl/01_grants.
- **047_device_provisioning.rollback.sql:** revierte el changeset device provisioning de 03_dcl/01_grants.
- **048_device_hardware_claim.rollback.sql:** revierte el changeset device hardware claim de 03_dcl/01_grants.
- **049_device_wifi_status.rollback.sql:** revierte el changeset device wifi status de 03_dcl/01_grants.
- **050_home_billing_references.rollback.sql:** revierte el changeset home billing references de 03_dcl/01_grants.
- **051_home_mini_budget.rollback.sql:** revierte el changeset home mini budget de 03_dcl/01_grants.
- **052_managed_user_overview.rollback.sql:** revierte el changeset managed user overview de 03_dcl/01_grants.
- **054_device_link_by_hardware.rollback.sql:** revierte el changeset device link by hardware de 03_dcl/01_grants.
- **055_device_delete_unlinked.rollback.sql:** revierte el changeset device delete unlinked de 03_dcl/01_grants.

### 03_dcl / 02_policies

Revierte políticas RLS. Este tipo de reversión puede abrir acceso a filas o bloquear por completo flujos de la aplicación.

- **001_rls_policies.rollback.sql:** revierte el changeset rls policies de 03_dcl/02_policies.
- **002_readonly_rls_policies.rollback.sql:** revierte el changeset readonly rls policies de 03_dcl/02_policies.
- **003_rls_domain_tables.rollback.sql:** revierte el changeset rls domain tables de 03_dcl/02_policies.
- **004_ingest_rls_hardening.rollback.sql:** revierte el changeset ingest rls hardening de 03_dcl/02_policies.
- **005_rbac_policy_enforcement.rollback.sql:** revierte el changeset rbac policy enforcement de 03_dcl/02_policies.
- **006_device_update_scope.rollback.sql:** revierte el changeset device update scope de 03_dcl/02_policies.
- **007_private_domain_rls.rollback.sql:** revierte el changeset private domain rls de 03_dcl/02_policies.
- **008_ingest_security_definer.rollback.sql:** revierte el changeset ingest security definer de 03_dcl/02_policies.
- **009_device_history_insert.rollback.sql:** revierte el changeset device history insert de 03_dcl/02_policies.
- **019_ticket_response_owner_visibility.rollback.sql:** revierte el changeset ticket response owner visibility de 03_dcl/02_policies.
- **020_cross_tenant_hardening.rollback.sql:** revierte el changeset cross tenant hardening de 03_dcl/02_policies.
- **021_actuator_command_rls.rollback.sql:** revierte el changeset actuator command rls de 03_dcl/02_policies.

## Ausencias que conviene conocer

- 01_ddl/02_types, 01_ddl/04_views y la mayor parte de
  01_ddl/05_materialized_views no tienen scripts externos en esta carpeta.
- Las numeraciones faltantes no deben suponerse como archivos perdidos: varias
  migraciones no fueron creadas, fueron sustituidas por cambios posteriores o
  conservan su rollback dentro del propio changelog.
- En 02_dml no hay rollback externo para los catálogos iniciales 001 a 009.
  Eliminar catálogos activos debe ser una decisión manual y validada.
- En 03_dcl existen cambios con reversa en línea, por ejemplo algunos grants
  puntuales de funciones. Consulta siempre el 0000changelog.yaml original
  antes de decidir que una reversión no existe.
- 04_tcl no tiene scripts de rollback externos: sus cambios son operativos y
  deben revertirse o compensarse manualmente según el caso.

## Antes de ejecutar

Para encontrar el contexto de un rollback, abre el archivo de igual nombre sin
el sufijo .rollback.sql en la capa original y revisa su changeset. Después de
la operación, ejecuta liquibase validate, verifica el estado de la aplicación
y conserva evidencia del backup, del SQL aplicado y del resultado.
