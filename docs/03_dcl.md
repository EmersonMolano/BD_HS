# 03_dcl: roles, privilegios y políticas de acceso

## Propósito

La capa 03_dcl controla quién se conecta a PostgreSQL, qué puede ejecutar cada
rol técnico y qué filas puede ver o modificar. Complementa la seguridad del
backend: no sustituye autorización de API, sino que reduce el impacto de un
error y aísla los datos de usuarios y hogares.

Sus roles principales son:

- hidro_smart_app: operaciones normales del backend.
- hidro_smart_ingest: recepción mínima de telemetría IoT.
- hidro_smart_readonly: lectura de reportes autorizados.

## Orden de carga real

El archivo BD_HS/changelog-master.yaml carga 00_roles antes de 01_ddl, porque
algunas migraciones necesitan que hidro_smart_app ya exista. Luego carga DDL,
DML y, por último, BD_HS/03_dcl/changelog.yaml.

El changelog propio de 03_dcl carga:

1. 01_grants
2. 02_policies

Cada carpeta usa 0000changelog.yaml como manifiesto de Liquibase. Los
contextos y labels ayudan a identificar cambios DCL, pero no reemplazan la
validación de permisos ni las pruebas de acceso por rol.

## 00_roles: cuentas técnicas de PostgreSQL

Esta carpeta no está incluida desde 03_dcl/changelog.yaml: se incluye
directamente desde el changelog maestro antes del DDL.

- **001_create_roles.sql:** crea, si no existen, los roles técnicos
  hidro_smart_app y hidro_smart_readonly con atributos de conexión limitados.
- **002_create_ingest_role.sql:** crea el rol hidro_smart_ingest sin
  privilegios administrativos, sin herencia y con límite de conexiones.
- **003_role_timezone_defaults.sql:** configura la zona horaria operativa por
  defecto en los tres roles técnicos.

Su 0000changelog.yaml define los tres changesets y sus reversas disponibles.

## 01_grants: principio de mínimo privilegio

Los scripts de esta carpeta conceden solo lo necesario y revocan accesos
amplios o públicos. El backend debe usar funciones SQL controladas en vez de
CRUD global sobre tablas sensibles.

- **001_grants_app_user.sql:** da a hidro_smart_app acceso base de conexión,
  esquemas y objetos necesarios para iniciar la aplicación.
- **002_grants_materialized_views.sql:** permite leer vistas materializadas
  autorizadas de consumo, alertas y dispositivos desde app y readonly.
- **003_grants_ingest.sql:** concede a hidro_smart_ingest conexión, uso del
  esquema consumption e inserción inicial de lecturas.
- **004_security_hardening.sql:** revoca lecturas sobre credenciales y tokens,
  y restringe funciones sensibles que no deben quedar expuestas.
- **005_grant_hourly_mv.sql:** habilita lectura de la vista materializada
  horaria para app y readonly.
- **006_grant_period_cost.sql:** concede ejecución de la función que calcula
  costo de consumo por período.
- **007_grant_login_security.sql:** deja las funciones de intentos de login
  accesibles solo para hidro_smart_app, no para PUBLIC.
- **008_grant_least_privilege_auth_rbac.sql:** restringe tablas de
  credenciales, MFA, auditoría y RBAC; deja al backend las lecturas y
  funciones estrictamente requeridas.
- **009_fn_cost_rollback_guard.sql:** concede al backend la función de costo
  con su firma compatible.
- **010_revoke_sensitive_token_crud.sql:** elimina CRUD directo del backend
  sobre tokens de restablecimiento, sesiones y datos relacionados.
- **011_grant_app_table_privileges.sql:** revoca privilegios globales y
  vuelve a conceder acceso directo únicamente a tablas seleccionadas.
- **012_grant_registration_flows.sql:** protege funciones de registro y
  permite al backend ejecutar solamente los flujos controlados de registro de
  usuario y dispositivo.
- **013_grant_device_management.sql:** concede la función que comprueba si el
  usuario puede administrar un dispositivo.
- **014_readonly_reporting_privileges.sql:** restringe hidro_smart_readonly a
  vistas, funciones y agregados aptos para reportes.
- **015_revoke_public_security_definers.sql:** quita de PUBLIC las funciones
  SECURITY DEFINER y vuelve a otorgar solo las necesarias al rol de aplicación.
- **016_restrict_privacy_table_writes.sql:** impide que la aplicación borre
  consentimientos o solicitudes ARCO y restringe escrituras sensibles.
- **017_revoke_scope_helpers_public.sql:** evita que helpers de alcance por
  hogar o dispositivo puedan invocarse desde PUBLIC.
- **018_secure_mv_access.sql:** elimina acceso directo amplio a vistas
  materializadas multi-hogar y orienta el acceso hacia funciones filtradas.
- **019_grant_ingest_references.sql:** concede REFERENCES sobre la relación
  hogar-dispositivo para validar la FK compuesta durante la ingesta.
- **020_ingest_minimum_privileges.sql:** ajusta a lo mínimo los permisos de
  ingestión para validar referencias e invocar la función de aceptación.
- **021_device_history_insert.sql:** permite al backend insertar historial de
  dispositivo.
- **022_device_status_update_function.sql:** concede la función controlada
  para actualizar estado del dispositivo.
- **023_session_token_functions.sql:** permite crear, rotar y revocar sesiones
  mediante funciones, sin exponer tablas de sesión.
- **024_password_functions.sql:** permite las funciones controladas de
  credenciales, cambio de contraseña y restablecimiento.
- **025_auth_security_function.sql:** concede consulta del estado de
  seguridad de autenticación.
- **026_active_password_policy_function.sql:** concede lectura de la política
  de contraseña activa mediante función.
- **027_alert_generation_function.sql:** permite generar eventos de alerta a
  través de la función de dominio.
- **028_role_management_functions.sql:** controla las funciones de consulta,
  asignación y retiro de roles de usuario.
- **029_preference_catalog_read.sql:** concede lectura de los catálogos
  públicos de idioma y moneda; no da acceso a preferencias ajenas.
- **030_audit_read_function.sql:** habilita la función paginada y controlada
  de lectura de auditoría.
- **031_authorization_context_function.sql:** concede al backend la función
  protegida que establece o consulta el contexto de autorización de la sesión.
- **032_final_security_hardening.sql:** aplica revocaciones finales sobre
  objetos sensibles para cerrar permisos directos no deseados.
- **033_auth_and_iot_functions.sql:** habilita funciones de verificación de
  correo, sesiones y operaciones IoT que el backend necesita.
- **034_auth_hardening_functions.sql:** permite revocar de forma controlada
  sesiones refresh pertenecientes al usuario.
- **035_iot_ingest_metrics_function.sql:** concede la función de ingesta que
  recibe métricas completas de un sensor.
- **036_device_status_ingest_function.sql:** concede la función que registra
  estados MQTT del dispositivo.
- **037_session_management_functions.sql:** permite listar, cerrar una sesión
  propia o cerrar las demás sesiones del usuario.
- **038_account_lifecycle_functions.sql:** habilita cambios controlados de
  estado y eliminación de cuentas.
- **039_list_managed_users_function.sql:** permite al administrador listar
  usuarios administrables mediante función filtrada.
- **040_telemetry_ingest_function.sql:** actualiza el permiso de ejecución de
  la firma vigente de ingesta de telemetría.
- **041_revoke_ingest_direct_insert.sql:** retira a ingest el INSERT directo
  en sensor_reading; la telemetría debe entrar por la función protegida.
- **042_password_reset_context.sql:** habilita recuperar el correo asociado a
  un token de restablecimiento con una función controlada.
- **043_actuator_command.sql:** protege tablas y funciones de actuadores, y
  concede a la app el acceso mínimo para registrar y consultar comandos.
- **044_actuator_timeout.sql:** permite ejecutar el cierre por tiempo de
  comandos de actuador pendientes.
- **045_device_registration_and_linking.sql:** habilita el registro con
  ubicación y la vinculación controlada de dispositivo a hogar.
- **046_consumption_series.sql:** concede la función que entrega series de
  consumo por hogar y período.
- **047_device_provisioning.sql:** permite registrar y actualizar el estado
  de aprovisionamiento de un dispositivo.
- **048_device_hardware_claim.sql:** permite reclamar un equipo
  aprovisionado usando su hardwareId.
- **049_device_wifi_status.sql:** permite guardar el SSID activo sin exponer
  ni almacenar la contraseña Wi-Fi.
- **050_home_billing_references.sql:** habilita crear hogares con perfil de
  facturación y sincronizar sus referencias tarifarias.
- **051_home_mini_budget.sql:** concede las funciones de perfil HidroSmart
  mini y consulta de estado de presupuesto.
- **052_managed_user_overview.sql:** habilita el resumen administrativo de un
  usuario gestionado.
- **053_home_members_list.sql:** permite listar nombres y roles de miembros
  de un hogar autorizado.
- **054_device_link_by_hardware.sql:** habilita vincular un dispositivo
  activo a un hogar por su hardwareId.
- **055_device_delete_unlinked.sql:** permite eliminar de forma controlada un
  dispositivo que ya no está vinculado a un hogar.

El archivo 0000changelog.yaml registra los cambios anteriores en orden
numérico. Cuando un changeset cuenta con rollback externo, referencia el
archivo correspondiente en 05_rollbacks/03_dcl/01_grants; algunos rollbacks
pequeños están definidos en línea dentro del changelog.

## 02_policies: Row-Level Security

RLS limita las filas que un rol puede leer o modificar incluso si posee
permiso sobre la tabla. Las políticas se basan en el usuario de aplicación y
en su pertenencia vigente a cada hogar.

- **001_rls_policies.sql:** activa RLS y define el conjunto inicial de
  políticas para cuentas, hogares, dispositivos, lecturas y auditoría.
- **002_readonly_rls_policies.sql:** permite al rol de reportes leer solo las
  filas y agregados autorizados bajo RLS.
- **003_rls_domain_tables.sql:** amplía RLS a preferencias, membresías,
  metas, alertas, reportes, tickets y demás tablas de dominio.
- **004_ingest_rls_hardening.sql:** restringe la inserción de telemetría a
  dispositivos activos asociados al hogar recibido.
- **005_rbac_policy_enforcement.sql:** sustituye políticas permisivas por
  políticas que además verifican permisos funcionales RBAC.
- **006_device_update_scope.sql:** exige devices.manage y membresía activa del
  hogar antes de actualizar un dispositivo.
- **007_private_domain_rls.sql:** protege perfiles privados, historial IoT y
  tablas de privacidad que reciben privilegios directos de la app.
- **008_ingest_security_definer.sql:** reemplaza políticas temporales de
  ingestión por la validación de una función SECURITY DEFINER.
- **009_device_history_insert.sql:** limita la inserción de historial de
  dispositivo a gestores autorizados con contexto de usuario.
- **019_ticket_response_owner_visibility.sql:** permite al dueño del ticket
  leer el historial completo de respuestas de su ticket.
- **020_cross_tenant_hardening.sql:** cierra accesos cruzados entre hogares o
  tickets al endurecer reportes, notificaciones, respuestas y solicitudes
  ARCO.
- **021_actuator_command_rls.sql:** aísla el estado y los comandos de
  actuadores por membresía activa de hogar.

El archivo 0000changelog.yaml registra estas políticas y sus rollbacks. Los
números 010 a 018 no están presentes como archivos físicos en esta carpeta; no
deben inventarse ni referenciarse hasta que exista una migración real.

## Verificación recomendada

Después de cambiar esta capa, prueba al menos:

1. hidro_smart_app puede ejecutar los flujos autorizados y no leer tablas
   sensibles directamente.
2. hidro_smart_ingest no puede insertar telemetría fuera de la función
   permitida ni consultar datos de hogares.
3. hidro_smart_readonly no puede modificar datos.
4. Owner, Guest y Administrator no ven ni editan filas de hogares ajenos.
5. liquibase validate y status --verbose muestran el orden esperado antes de
   aplicar update.
