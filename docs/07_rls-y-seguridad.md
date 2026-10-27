# Seguridad y aislamiento por filas (RLS)

La base de datos agrega una barrera de autorización a los permisos de la API.
Los cambios viven en [`03_dcl`](../03_dcl), principalmente en roles, grants,
políticas y funciones de contexto. Revisa la migración real antes de cambiar
privilegios: varios cambios son acumulativos y sensibles al orden.

## Roles técnicos

- `hidro_smart_app`: operaciones de la aplicación; recibe privilegios limitados
  y, para operaciones sensibles, ejecuta funciones autorizadas.
- `hidro_smart_ingest`: identidad específica de ingesta IoT. No debe recibir
  lectura global de hogares/dispositivos ni inserción directa si la migración
  vigente revoca ese acceso; la telemetría entra por la función concedida.
- `hidro_smart_readonly`: acceso de consulta restringido, con políticas propias.
- El propietario de migraciones es una identidad de despliegue, no la credencial
  que debe usar la aplicación en ejecución.

Los nombres, membresías y permisos efectivos se definen en
[`03_dcl/00_roles`](../03_dcl/00_roles) y [`03_dcl/01_grants`](../03_dcl/01_grants).
No copies contraseñas desde `.env` a documentación ni a scripts.

## Cómo funciona el aislamiento

1. El backend autentica al usuario y valida permiso funcional.
2. Para operaciones con sesión de usuario, establece el contexto transaccional
   que leen las funciones de autorización de PostgreSQL.
3. Las políticas RLS filtran filas por identidad y pertenencia al hogar; las
   reglas de propietario restringen cambios como gestionar miembros o vínculos.
4. Las funciones `SECURITY DEFINER` tienen propietario, `search_path` y grants
   que deben revisarse cuidadosamente; no equivalen a acceso irrestricto de la
   cuenta de aplicación.
5. La ingesta tiene su propio rol y funciones controladas para validar el
   dispositivo, su vínculo y los datos de la lectura.

RLS no reemplaza la autorización en la API, y la autorización de la API no
reemplaza RLS. Ambas capas deben mantenerse alineadas. Un endpoint nuevo que
consulta directamente tablas debe establecer contexto dentro de la misma
transacción y usar un rol con privilegios mínimos.

## Cambios y comprobaciones seguras

- Agrega permisos mediante migraciones versionadas; evita otorgar `ALL` o
  privilegios a `PUBLIC`.
- Revisa `USING` y `WITH CHECK`: el primero controla filas visibles/afectables y
  el segundo valida la fila nueva en inserciones o actualizaciones.
- Prueba al menos dos hogares aislados, usuario sin membresía, miembro y
  propietario; incluye una prueba negativa de lectura y de escritura cruzada.
- Comprueba los grants y políticas con roles de runtime, no únicamente como
  superusuario: un superusuario puede eludir RLS y ocultar errores de diseño.
- Ejecuta `liquibase validate`, `status --verbose`, las pruebas de integración
  y revisa que una excepción haga rollback del contexto de usuario.

Para el inventario de roles y políticas, consulta
[`03_dcl.md`](03_dcl.md) y los SQL versionados. Esta guía no promete que una
política exista solo por aparecer en el diagrama: la migración aplicada es la
fuente de verdad.
