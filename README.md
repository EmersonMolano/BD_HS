# Base de datos HidroSmart

PostgreSQL versionado con Liquibase. Las migraciones son la fuente de verdad
del esquema, catálogos, funciones, roles y políticas RLS.

## Estructura

| Ruta | Propósito |
| --- | --- |
| `changelog-master.yaml` | Punto de entrada de Liquibase. |
| `01_ddl` | Esquemas, tablas, tipos, funciones, vistas, índices y triggers. |
| `02_dml` | Catálogos, permisos funcionales, datos iniciales y códigos IoT preasignados. |
| `03_dcl` | Roles PostgreSQL, grants y políticas RLS. |
| `05_rollbacks` | Referencias de rollback manual; no se ejecutan durante `update`. |

## Ejecutar migraciones

Desde la raíz del repositorio, con la pila de datos levantada:

```powershell
docker compose --env-file .env up -d postgres db-bootstrap
docker compose --env-file .env --profile tooling run --rm liquibase validate
docker compose --env-file .env --profile tooling run --rm liquibase status --verbose
docker compose --env-file .env --profile tooling run --rm liquibase update
```

No edites un changeset aplicado. Para cambiar el esquema crea un changeset
nuevo, actualiza su changelog correspondiente y valida en una base local nueva.

Consulta [docs/README.md](docs/README.md) para modelo, seguridad y reglas de
migración.
