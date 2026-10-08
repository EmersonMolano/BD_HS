# Auditoria del esquema PostgreSQL

Fecha de verificacion: **2026-09-23**.

## Inventario

La base local `hidro_smart` tiene 58 tablas base: 56 de aplicacion y 2 de
infraestructura de Liquibase (`public.databasechangelog` y
`public.databasechangeloglock`). Tambien tiene 5 vistas materializadas.

| Dominio | Tablas base | Vistas materializadas |
|---|---:|---:|
| `user_account` | 14 | 0 |
| `preference` | 4 | 0 |
| `home` | 7 | 0 |
| `device` | 6 | 1 |
| `consumption` | 5 | 2 |
| `alert_rate` | 7 | 1 |
| `analytics_support` | 9 | 1 |
| `audit` | 2 | 0 |
| `privacy` | 2 | 0 |
| `public` | 2 | 0 |

## Verificacion de uso

No se encontro una tabla de aplicacion sin referencias. Todas participan en al
menos una de estas relaciones:

- repositorio o ruta del backend;
- funcion, procedimiento, vista o job SQL;
- clave foranea, indice, RLS o catalogo de dominio;
- historial operativo o capacidad prevista del producto.

No se eliminan tablas vacias sin una decision de producto y una migracion de
deprecacion. En particular, `consumption_prediction`, los resumenes de
consumo, `home.home_user_function` y `alert_rate.alert_notification` estan
preparados para funcionalidades que todavia no generan filas en este entorno.

## Relaciones IoT verificadas

```text
device.device
    -> home.home_device
    -> consumption.sensor_reading
    -> device.device_telemetry_history
```

El identificador fisico `hardware_id` tiene un indice unico parcial; el codigo
MQTT `code` tiene una restriccion unica. La base no almacena contrasenas Wi-Fi.
La lectura MQTT se deduplica mediante el indice unico de
`mqtt_message_id` por dispositivo.

## Integridad

El changeset `20260923-validate-iot-metric-constraints` valido las 15
restricciones IoT que estaban en estado `NOT VALID`. El resultado actual es:

```text
restricciones IoT invalidas: 0
changesets Liquibase: 239
```

No se detectaron hogares, dispositivos ni lecturas porque el entorno quedo
limpio despues de las pruebas de integracion. Esto no representa una falla del
esquema.
