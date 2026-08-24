# Informe de concurrencia

Base de trabajo: `food_store_tp2`. Script de apoyo: `sql/03_laboratorio_concurrencia.sql`. Antes de abrir los escenarios, verificar la conexion conforme a `protocolo_seguridad.md` y definir el mismo marcador unico en ambas sesiones. Reemplazar `LAB_CONC_2026_CAMBIAR` por un valor unico antes de ejecutar.

```sql
\set ON_ERROR_STOP on
\set laboratorio_id 'LAB_CONC_2026_CAMBIAR'
```

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

**Resultado esperado segun PostgreSQL.** En `READ COMMITTED`, cada sentencia ve una instantanea nueva y el segundo valor puede ser `20.00`. En `REPEATABLE READ`, ambas lecturas de A pertenecen a la instantanea inicial y deben conservar el mismo valor, aunque B confirme `30.00`.

**Observacion real del motor: PENDIENTE DE EJECUCION.** Registrar los dos valores leidos, mensajes de `BEGIN` y `COMMIT`, version del motor y capturas.

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

**Resultado esperado segun PostgreSQL.** En `READ COMMITTED`, el segundo conteo puede aumentar en uno. En `REPEATABLE READ`, el segundo conteo debe ser igual al primero porque A conserva su instantanea inicial; la fila insertada por B no es visible para esa transaccion.

**Observacion real del motor: PENDIENTE DE EJECUCION.** Registrar ambos conteos por aislamiento y la confirmacion de cada insercion de B.

## 3. Espera por bloqueo

**Objetivo.** Evidenciar una espera de bloqueo de fila limitada a diez segundos.

Sesion A, conservar la transaccion abierta despues del `SELECT` mientras se ejecuta B:

```sql
BEGIN;
SET LOCAL lock_timeout = '10s';
SELECT id_producto FROM producto WHERE nombre = :'laboratorio_id' || '_BLOQUEO' AND id_categoria = (SELECT id_categoria FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id') FOR UPDATE;
COMMIT;
```

Sesion B, mientras A conserva el bloqueo:

```sql
BEGIN;
SET LOCAL lock_timeout = '10s';
SELECT id_producto FROM producto WHERE nombre = :'laboratorio_id' || '_BLOQUEO' AND id_categoria = (SELECT id_categoria FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id') FOR UPDATE;
COMMIT;
```

**Resultado esperado segun PostgreSQL.** Si A libera la fila mediante `COMMIT` o `ROLLBACK` antes de diez segundos, B puede terminar el `SELECT` y confirmar. Si A no la libera, B recibe un error de `lock timeout`; este es un resultado de seguridad controlado. PostgreSQL cancela la sentencia y la transaccion de B queda abortada, por lo que B debe ejecutar `ROLLBACK;` antes de continuar.

**Observacion real del motor: PENDIENTE DE EJECUCION.** Registrar hora de inicio de B, hora de liberacion o vencimiento, mensaje final de B y, si hubo `lock timeout`, el `ROLLBACK` ejecutado.

## Limpieza final (sesion A)

```sql
BEGIN;
DELETE FROM detalle_pedido WHERE id_producto IN (SELECT p.id_producto FROM producto p JOIN categoria c ON c.id_categoria = p.id_categoria WHERE c.descripcion = 'Semilla TP2: ' || :'laboratorio_id');
DELETE FROM producto p USING categoria c WHERE p.id_categoria = c.id_categoria AND c.descripcion = 'Semilla TP2: ' || :'laboratorio_id';
DELETE FROM categoria WHERE descripcion = 'Semilla TP2: ' || :'laboratorio_id';
COMMIT;
```

## Checklist de evidencia real

- [ ] Usar el mismo `laboratorio_id` unico en ambas sesiones.
- [ ] Ejecutar preparacion y limpieza final en `food_store_tp2`.
- [ ] Abrir dos sesiones `psql` independientes.
- [ ] Reemplazar cada campo **PENDIENTE DE EJECUCION** por salidas o capturas reales.
- [ ] Conservar comandos, version de PostgreSQL y nivel de aislamiento usado.
- [ ] No presentar resultados esperados como resultados observados.
