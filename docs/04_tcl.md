# 04_tcl: operaciones transaccionales y administrativas

## Propósito

La capa 04_tcl reúne bloques operativos de transacción, recuperaciones
manuales y metadatos de versión. No crea el modelo principal ni define los
privilegios de la aplicación.

Aunque se llama TCL, contiene SQL administrativo y de mantenimiento además de
bloques transaccionales. Debe ejecutarse con revisión humana, especialmente
cuando modifica resúmenes o recupera cuentas.

## Cómo se relaciona con Liquibase

BD_HS/changelog-master.yaml no incluye 04_tcl. Por tanto, una actualización
normal del esquema no ejecuta esta capa.

El changelog de 04_tcl solo incluye 00_transaction_blocks y lo marca con el
contexto 04_tcl_manual. Las carpetas 01_manual_recoveries y 02_release_tags
tienen manifiestos propios, pero no están incluidas por el changelog raíz.
Se conservan como procedimientos de operación manual, no como pasos
automáticos del despliegue.

Los archivos 0000changelog.yaml describen los changesets y usan SELECT 1 como
rollback cuando la acción no tiene una reversión automática segura.

## 00_transaction_blocks: resumen diario

- **001_daily_summary_transaction.sql:** ejecuta un bloque DO que elimina el
  resumen del día actual y lo vuelve a calcular desde sensor_reading,
  agrupándolo por hogar. Si ocurre un error, lo propaga y PostgreSQL revierte
  el bloque. Debe usarse con cuidado: recalcula únicamente CURRENT_DATE.

Su 0000changelog.yaml es el único incluido desde 04_tcl/changelog.yaml. El
comentario “iniciar/confirmar transacción” dentro del SQL es explicativo: el
bloque DO no abre ni cierra una transacción SQL independiente.

## 01_manual_recoveries: recuperación dirigida

- **001_recover_deleted_user.sql:** contiene, dentro de un comentario, el
  UPDATE para reactivar una cuenta con soft delete. Debe reemplazarse
  UUID_DEL_USUARIO por el UUID real, revisarse y ejecutarse manualmente; tal
  como está guardado no modifica nada porque el UPDATE está comentado.

El comentario del manifiesto menciona un resumen diario, pero el contenido real
del archivo es recuperación de usuario. Para operar se debe seguir el SQL
real, no esa descripción heredada.

## 02_release_tags: metadatos de liberación

- **001_tag_v1_0_0.sql:** añade un comentario de versión a la base de datos,
  crea public.schema_version si falta y registra la versión 1.0.0.

El 0000changelog.yaml de la carpeta define como rollback la eliminación del
registro 1.0.0. El comentario de la base y la tabla creada no se revierten por
ese rollback, por lo que no debe tratarse como una reversión completa.

## Uso seguro

1. Haz backup antes de ejecutar cualquier archivo de 04_tcl en un entorno con
   datos reales.
2. Ejecuta primero en una copia de prueba y comprueba las filas afectadas.
3. Para la recuperación de usuario, confirma que no exista otra cuenta activa
   con el mismo correo o documento.
4. Para el resumen diario, compara conteos y totales antes y después.
5. Registra en auditoría o en la bitácora operativa quién ejecutó el script,
   cuándo y con qué parámetros.
