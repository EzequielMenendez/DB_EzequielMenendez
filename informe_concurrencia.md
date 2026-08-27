# Informe de concurrencia

Base de trabajo: `food_store_tp2`. Script de apoyo: `sql/03_laboratorio_concurrencia.sql`. Antes de abrir los escenarios, verificar la conexion conforme a `protocolo_seguridad.md` y definir el mismo marcador unico en ambas sesiones. Reemplazar `LAB_CONC_2026_CAMBIAR` por un valor unico antes de ejecutar.

```sql
\set ON_ERROR_STOP on
\set laboratorio_id 'LAB_CONC_TEST'
```

Version del motor: **PostgreSQL 18.6 on x86_64-windows, compiled by msvc-19.44.35228, 64-bit**.

## Preparacion (sesion A)

```sql
BEGIN;
DELETE FROM detalle_pedido WHERE id_producto IN (SELECT p.id_producto FROM producto p JOIN categoria c ON c.id_categoria = p.id_categoria WHERE c.descripcion = 'Semilla TP2: ' || :'laboratorio_id');
DELETE FROM producto p USING categoria c WHERE p.id_categoria = c.id_categoria AND c.descripcion = 'Semilla TP2: ' || :'laboratorio_id';
DELETE FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id';
INSERT INTO categoria (nombre, descripcion) VALUES (:'laboratorio_id', 'Semilla TP2: ' || :'laboratorio_id');
INSERT INTO producto (nombre, precio_lista, stock, activo, id_categoria) SELECT :'laboratorio_id' || '_PRECIO', 10.00, 10, TRUE, id_categoria FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id';
INSERT INTO producto (nombre, precio_lista, stock, activo, id_categoria) SELECT :'laboratorio_id' || '_BLOQUEO', 15.00, 10, TRUE, id_categoria FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id';
COMMIT;
```

**Observacion real:** `BEGIN`, `DELETE 0` x3, `INSERT 0 1` x3, `COMMIT`. Semilla creada con 2 productos (`LAB_CONC_TEST_PRECIO` y `LAB_CONC_TEST_BLOQUEO`).

## 1. Lectura no repetible

**Objetivo.** Comparar dos lecturas de `producto.precio_lista` dentro de una transaccion mientras otra sesion actualiza la fila.

**Orden de comandos.** Ejecutar primero en A el primer bloque y detenerse despues de su primer `SELECT`. Ejecutar B completo. Luego ejecutar en A las dos sentencias restantes. Repetir el mismo orden para `REPEATABLE READ`.

Sesion A, `READ COMMITTED`:

```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT precio_lista FROM producto WHERE nombre = :'laboratorio_id' || '_PRECIO' AND id_categoria = (SELECT id_categoria FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id');
SELECT precio_lista FROM producto WHERE nombre = :'laboratorio_id' || '_PRECIO' AND id_categoria = (SELECT id_categoria FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id');
COMMIT;
```

Sesion B, entre los `SELECT` de A:

```sql
BEGIN;
UPDATE producto SET precio_lista = 20.00 WHERE nombre = :'laboratorio_id' || '_PRECIO' AND id_categoria = (SELECT id_categoria FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id');
COMMIT;
```

**Observacion real del motor (READ COMMITTED):**

| Momento    | precio_lista |
|------------|-------------|
| LECTURA_1  | 10.00       |
| LECTURA_2  | 20.00       |

La lectura no repetible se produjo: cada sentencia dentro de READ COMMITTED toma una nueva instantanea, por lo que la modificacion commiteada por B es visible en la segunda lectura de A.

Sesion A, `REPEATABLE READ`:

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT precio_lista FROM producto WHERE nombre = :'laboratorio_id' || '_PRECIO' AND id_categoria = (SELECT id_categoria FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id');
SELECT precio_lista FROM producto WHERE nombre = :'laboratorio_id' || '_PRECIO' AND id_categoria = (SELECT id_categoria FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id');
COMMIT;
```

Sesion B, entre los `SELECT` de A:

```sql
BEGIN;
UPDATE producto SET precio_lista = 30.00 WHERE nombre = :'laboratorio_id' || '_PRECIO' AND id_categoria = (SELECT id_categoria FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id');
COMMIT;
```

**Observacion real del motor (REPEATABLE READ):**

| Momento    | precio_lista |
|------------|-------------|
| LECTURA_1  | 10.00       |
| LECTURA_2  | 10.00       |

REPEATABLE READ conserva la instantanea inicial de toda la transaccion. La modificacion de B (`30.00`) no es visible para A, que conserva el valor `10.00` en ambas lecturas.

## 2. Lectura fantasma

**Objetivo.** Contar productos activos de la categoria de laboratorio mientras otra sesion inserta un nuevo producto activo.

Sesion A, `READ COMMITTED`:

```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT count(*) AS activos FROM producto WHERE activo AND id_categoria = (SELECT id_categoria FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id');
SELECT count(*) AS activos FROM producto WHERE activo AND id_categoria = (SELECT id_categoria FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id');
COMMIT;
```

Sesion B, entre los conteos de A:

```sql
BEGIN;
INSERT INTO producto (nombre, precio_lista, stock, activo, id_categoria) SELECT :'laboratorio_id' || '_FANTASMA', 5.00, 1, TRUE, id_categoria FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id';
COMMIT;
```

**Observacion real del motor (READ COMMITTED):**

| Momento  | activos |
|----------|---------|
| CONTEO_1 | 2       |
| CONTEO_2 | 3       |

La insercion de B es visible para A en la segunda lectura. READ COMMITTED permite lecturas fantasma porque cada sentencia ve una instantanea nueva.

Antes de repetir con `REPEATABLE READ`, sesion B ejecuta la limpieza exacta:

```sql
BEGIN;
DELETE FROM detalle_pedido WHERE id_producto IN (SELECT p.id_producto FROM producto p JOIN categoria c ON c.id_categoria = p.id_categoria WHERE p.nombre = :'laboratorio_id' || '_FANTASMA' AND c.descripcion = 'Semilla TP2: ' || :'laboratorio_id');
DELETE FROM producto p USING categoria c WHERE p.id_categoria = c.id_categoria AND p.nombre = :'laboratorio_id' || '_FANTASMA' AND c.descripcion = 'Semilla TP2: ' || :'laboratorio_id';
COMMIT;
```

Sesion A, `REPEATABLE READ`:

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT count(*) AS activos FROM producto WHERE activo AND id_categoria = (SELECT id_categoria FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id');
SELECT count(*) AS activos FROM producto WHERE activo AND id_categoria = (SELECT id_categoria FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id');
COMMIT;
```

Sesion B, entre los conteos de A:

```sql
BEGIN;
INSERT INTO producto (nombre, precio_lista, stock, activo, id_categoria) SELECT :'laboratorio_id' || '_FANTASMA', 5.00, 1, TRUE, id_categoria FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id';
COMMIT;
```

**Observacion real del motor (REPEATABLE READ):**

| Momento  | activos |
|----------|---------|
| CONTEO_1 | 2       |
| CONTEO_2 | 2       |

REPEATABLE READ previene la lectura fantasma: A conserva su instantanea inicial y la fila insertada por B no es visible para esa transaccion.

## 3. Espera por bloqueo

**Objetivo.** Evidenciar una espera de bloqueo de fila limitada a diez segundos.

Sesion A, conservar la transaccion abierta despues del `SELECT` mientras se ejecuta B:

```sql
BEGIN;
SET LOCAL lock_timeout = '15s';
SELECT id_producto FROM producto WHERE nombre = :'laboratorio_id' || '_BLOQUEO' AND id_categoria = (SELECT id_categoria FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id') FOR UPDATE;
SELECT pg_sleep(12);
COMMIT;
```

Sesion B, mientras A conserva el bloqueo (lock_timeout = 5s):

```sql
BEGIN;
SET LOCAL lock_timeout = '5s';
SELECT id_producto FROM producto WHERE nombre = :'laboratorio_id' || '_BLOQUEO' AND id_categoria = (SELECT id_categoria FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id') FOR UPDATE;
COMMIT;
```

**Observacion real del motor:**

- **Sesion A:** `BEGIN`, `SET`, `id_producto = 6` (1 fila), `pg_sleep` completado, `COMMIT`.
- **Sesion B:** `BEGIN`, `SET`, luego **ERROR:**
  ```
  ERROR: cancelando la sentencia debido a que se agoto el tiempo de espera de "locks"
  CONTEXTO: mientras se bloqueaba la tupla (0,4) de la relacion «producto»
  ```

La sesion B intento adquirir el bloqueo `FOR UPDATE` sobre la misma fila que A mantiene abierto. Como el `lock_timeout` de B (5 segundos) se agoto antes de que A liberara la fila (12 segundos), PostgreSQL cancelo la sentencia con el error de lock timeout. La transaccion de B quedo abortada y requirio `ROLLBACK` antes de continuar.

## Limpieza final (sesion A)

```sql
BEGIN;
DELETE FROM detalle_pedido WHERE id_producto IN (SELECT p.id_producto FROM producto p JOIN categoria c ON c.id_categoria = p.id_categoria WHERE c.descripcion = 'Semilla TP2: ' || :'laboratorio_id');
DELETE FROM producto p USING categoria c WHERE p.id_categoria = c.id_categoria AND c.descripcion = 'Semilla TP2: ' || :'laboratorio_id';
DELETE FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id';
COMMIT;
```

**Observacion real:** `BEGIN`, `DELETE 0`, `DELETE 3`, `DELETE 1`, `COMMIT`. Limpieza completada.

## Checklist de evidencia real

- [x] Usar el mismo `laboratorio_id` unico en ambas sesiones.
- [x] Ejecutar preparacion y limpieza final en `food_store_tp2`.
- [x] Abrir dos sesiones `psql` independientes.
- [x] Reemplazar cada campo **PENDIENTE DE EJECUCION** por salidas o capturas reales.
- [x] Conservar comandos, version de PostgreSQL y nivel de aislamiento usado.
- [x] No presentar resultados esperados como resultados observados.
