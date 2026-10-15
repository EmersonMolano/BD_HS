# 02_dml: datos iniciales y correcciones de datos

## Propósito

La capa 02_dml carga y ajusta datos que dependen de la estructura creada por
01_ddl: catálogos, roles funcionales, tarifas de referencia, códigos lógicos
preasignados para ESP32 y correcciones puntuales.

No crea tablas ni permisos de base de datos. La estructura corresponde a
01_ddl; los privilegios y RLS corresponden a 03_dcl.

## Cómo se ejecuta

BD_HS/changelog-master.yaml incluye esta capa después de 01_ddl y antes de los
grants y políticas de 03_dcl. Su changelog raíz conserva este orden:

1. 00_inserts
2. 01_updates
3. 02_deletes
4. 03_upserts
5. 04_patches

Los archivos 0000changelog.yaml de cada subcarpeta son manifiestos de
Liquibase: registran los changesets, su orden y, cuando existe, el rollback.
No contienen datos por sí mismos.

Importante: Liquibase evita ejecutar otra vez un changeset ya registrado en
DATABASECHANGELOG. Eso no convierte automáticamente todos los SQL en seguros
para ejecutarlos manualmente dos veces; varios inserts iniciales no usan
ON CONFLICT y podrían duplicar o fallar si se lanzan fuera de Liquibase.

## 00_inserts: catálogos y valores iniciales

Esta carpeta carga los datos de referencia necesarios para que la aplicación
arranque con roles, preferencias, soporte y parámetros de consumo.

- **001_roles.sql:** inserta los roles funcionales iniciales: Administrator,
  Support, HomeUser y Guest.
- **002_languages.sql:** crea o actualiza el catálogo de idiomas admitidos:
  español, inglés, portugués e italiano.
- **003_currencies.sql:** crea o actualiza el catálogo de monedas disponibles
  y su estado activo.
- **004_themes.sql:** inserta los temas visuales Light, Dark y High Contrast
  para las preferencias de usuario.
- **005_estratos.sql:** carga los estratos socioeconómicos 1 a 6 con valores
  base y porcentajes de subsidio iniciales.
- **006_ticket_categories.sql:** carga las categorías de soporte Dispositivo,
  Reportes, Tarifas, Detección y Otros.
- **007_ticket_priorities.sql:** carga las prioridades Baja, Media y Alta de
  los tickets.
- **008_ticket_statuses.sql:** carga los estados Abierto, En Proceso,
  Resuelto y Cerrado para los tickets.
- **009_password_policy.sql:** crea la política Default de contraseñas con
  longitud, complejidad, vencimiento y bloqueo por intentos.
- **010_rbac_permissions.sql:** inserta o actualiza permisos funcionales RBAC
  y asigna el conjunto inicial de permisos a los roles.
- **011_home_billing_references.sql:** actualiza los estratos e introduce
  referencias nacionales iniciales de tarifa y consumo para hogares que aún
  no tenían una tarifa propia. Son benchmarks técnicos, no una tarifa oficial
  definitiva del prestador.
- **012_home_billing_reference_excess_fix.sql:** corrige el valor de consumo
  excedente para estratos 4 a 6 y usos comercial o industrial, donde se usa
  una tarifa única por metro cúbico.
- **013_hidrosmart_mini_defaults.sql:** sustituye las referencias nacionales
  de desarrollo por los valores simplificados de HidroSmart mini; conserva las
  tarifas configuradas directamente por el usuario.

El archivo 0000changelog.yaml incluye los trece changesets en el orden
numérico anterior.

## 01_updates: reservada para actualizaciones dirigidas

La carpeta existe para cambios de filas ya creadas que no son una carga inicial.
Su 0000changelog.yaml está vacío: actualmente no hay scripts activos ni datos
que se modifiquen desde esta sección.

## 02_deletes: reservada para retiros controlados

La carpeta está destinada a eliminaciones explícitas y auditables de datos de
referencia. Su 0000changelog.yaml está vacío: actualmente no hay scripts
activos ni eliminaciones ejecutadas desde esta sección.

## 03_upserts: registros que pueden existir previamente

Esta sección se usa cuando un dato puede venir de una instalación anterior y
debe conservarse sin duplicarse.

- **001_preassigned_esp32_device_codes.sql:** reserva tres códigos lógicos
  únicos de ESP32 en device.device. Los crea sin hogar, con
  provisioning_status PENDING, y usa ON CONFLICT (code) DO NOTHING. El código
  lógico no es el hardwareId: el identificador físico eFuse se reclama después
  durante el flujo BLE/MQTT.

El archivo 0000changelog.yaml registra ese changeset y su rollback asociado en
05_rollbacks/02_dml/03_upserts.

## 04_patches: ajustes históricos

Aquí se concentran correcciones posteriores a un changeset ya aplicado. No se
deben reordenar: cada parche asume el estado dejado por los anteriores.

- **001_fix_user_account_delete_audit_trigger.sql:** evita que la auditoría
  impida borrar una cuenta cuando no hay usuario de sesión, dejando el actor de
  auditoría en NULL si corresponde.
- **002_fix_self_delete_audit.sql:** amplía la protección del parche anterior
  para el caso de autoeliminación, evitando que la FK de auditoría apunte al
  usuario que se elimina.
- **003_audit_event_semantics.sql:** ajusta las acciones permitidas en la
  auditoría y redefine el trigger de cuentas para distinguir creación,
  actualización, eliminación, desactivación, reactivación y bloqueo.
- **004_homeuser_device_permission.sql:** asigna devices.manage al rol
  HomeUser para registrar sus propios dispositivos; el alcance sigue limitado
  por RLS y funciones controladas.
- **005_actuators_permission.sql:** crea o actualiza actuators.manage y lo
  asigna a Administrator y HomeUser.
- **006_remove_support_role.sql:** elimina el rol funcional Support y sus
  asignaciones, sin borrar cuentas de usuario.

El archivo 0000changelog.yaml registra los seis cambios y apunta a los scripts
de reversión disponibles en 05_rollbacks/02_dml/04_patches.

## Relación con las demás capas

- Antes: 01_ddl debe haber creado los esquemas, tablas, funciones y
  restricciones que reciben estos datos.
- Después: 03_dcl concede los permisos mínimos para que backend, ingestión y
  reportes usen esos datos.
- Reversión: los rollbacks existentes están bajo
  05_rollbacks/02_dml. Revísalos antes de aplicarlos, especialmente los que
  eliminan catálogos o asignaciones en uso.
