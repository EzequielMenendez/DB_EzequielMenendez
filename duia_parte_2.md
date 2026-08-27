# DU/IA - Parte 2: concurrencia

## Declaracion transparente

- Herramienta de IA utilizada: OpenCode / OpenAI, modelo `openai/gpt-5.6-terra`.
- Uso: asistencia para redactar procedimientos coordinados de dos sesiones sobre el esquema Food Store.
- No se atribuyen a la IA ni al estudiante resultados de motor que no hayan sido capturados durante una ejecucion real.

## Prompt utilizado

> Disenar un laboratorio PostgreSQL para pegar manualmente en dos sesiones `psql` sobre Food Store. Incluir semilla y limpieza controladas, una lectura no repetible del precio de un producto comparando READ COMMITTED y REPEATABLE READ, una lectura fantasma contando productos activos con ambos niveles y una espera de bloqueo mediante SELECT FOR UPDATE. No fabricar salidas: indicar el orden exacto de las sentencias y distinguir comportamiento esperado de observacion real.

## Aporte de IA y control humano

La IA estructuro los bloques por sesion y aislamiento. La revision estatica incluyo el marcador unico compartido por ambas sesiones, filtros por la descripcion exacta de la semilla, limpieza transaccional y el limite de espera de bloqueo de diez segundos. El estudiante debe coordinar los puntos de espera, capturar las salidas y comprobar que la limpieza final se haya ejecutado.

## Verificacion real

Estado: **EJECUTADO**.

### Preparacion de la semilla

```sql
BEGIN;
DELETE FROM detalle_pedido WHERE id_producto IN (SELECT p.id_producto FROM producto p JOIN categoria c ON c.id_categoria = p.id_categoria WHERE c.descripcion = 'Semilla TP2: LAB_CONC_TEST');
DELETE FROM producto p USING categoria c WHERE p.id_categoria = c.id_categoria AND c.descripcion = 'Semilla TP2: LAB_CONC_TEST';
DELETE FROM categoria WHERE descripcion = 'Semilla TP2: LAB_CONC_TEST';
INSERT INTO categoria (nombre, descripcion) VALUES ('LAB_CONC_TEST', 'Semilla TP2: LAB_CONC_TEST');
INSERT INTO producto (nombre, precio_lista, stock, activo, id_categoria) SELECT 'LAB_CONC_TEST_PRECIO', 10.00, 10, TRUE, id_categoria FROM categoria WHERE descripcion = 'Semilla TP2: LAB_CONC_TEST';
INSERT INTO producto (nombre, precio_lista, stock, activo, id_categoria) SELECT 'LAB_CONC_TEST_BLOQUEO', 15.00, 10, TRUE, id_categoria FROM categoria WHERE descripcion = 'Semilla TP2: LAB_CONC_TEST';
COMMIT;
```

Salida: `BEGIN`, `DELETE 0` x3, `INSERT 0 1` x3, `COMMIT`.

### Escenario 1: Lectura no repetible (READ COMMITTED)

Sesion A:
```
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT 'LECTURA_1' AS momento, precio_lista ...  -> 10.00
SELECT pg_sleep(3);
SELECT 'LECTURA_2' AS momento, precio_lista ...  -> 20.00
COMMIT;
```

Sesion B (entre los SELECT de A):
```
BEGIN;
UPDATE producto SET precio_lista = 20.00 WHERE nombre = 'LAB_CONC_TEST_PRECIO';
COMMIT;
```

Resultado observado: **Lectura 1 = 10.00, Lectura 2 = 20.00.** La lectura no repetible se produjo porque READ COMMITTED toma una nueva instantanea por cada sentencia.

### Escenario 1B: Lectura no repetible (REPEATABLE READ)

Sesion A:
```
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT 'LECTURA_1' AS momento, precio_lista ...  -> 10.00
SELECT pg_sleep(3);
SELECT 'LECTURA_2' AS momento, precio_lista ...  -> 10.00
COMMIT;
```

Sesion B (entre los SELECT de A):
```
BEGIN;
UPDATE producto SET precio_lista = 30.00 WHERE nombre = 'LAB_CONC_TEST_PRECIO';
COMMIT;
```

Resultado observado: **Lectura 1 = 10.00, Lectura 2 = 10.00.** REPEATABLE READ conserva la instantanea inicial de toda la transaccion; la modificacion de B no es visible para A.

### Escenario 2: Lectura fantasma (READ COMMITTED)

Sesion A:
```
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT 'CONTEO_1' AS momento, count(*) AS activos ...  -> 2
SELECT pg_sleep(3);
SELECT 'CONTEO_2' AS momento, count(*) AS activos ...  -> 3
COMMIT;
```

Sesion B (entre los conteos de A):
```
BEGIN;
INSERT INTO producto (nombre, precio_lista, stock, activo, id_categoria)
  SELECT 'LAB_CONC_TEST_FANTASMA', 5.00, 1, TRUE, id_categoria
  FROM categoria WHERE descripcion = 'Semilla TP2: LAB_CONC_TEST';
COMMIT;
```

Resultado observado: **Conteo 1 = 2, Conteo 2 = 3.** La insercion de B es visible para A en la segunda lectura bajo READ COMMITTED.

### Escenario 2B: Lectura fantasma (REPEATABLE READ)

Sesion A:
```
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT 'CONTEO_1' AS momento, count(*) AS activos ...  -> 2
SELECT pg_sleep(3);
SELECT 'CONTEO_2' AS momento, count(*) AS activos ...  -> 2
COMMIT;
```

Sesion B (entre los conteos de A):
```
BEGIN;
INSERT INTO producto (...) SELECT 'LAB_CONC_TEST_FANTASMA', ...;
COMMIT;
```

Resultado observado: **Conteo 1 = 2, Conteo 2 = 2.** REPEATABLE READ previene la lectura fantasma: A conserva su instantanea inicial y la fila insertada por B no es visible.

### Escenario 3: Espera por bloqueo (lock timeout)

Sesion A (mantiene el bloqueo):
```
BEGIN;
SET LOCAL lock_timeout = '15s';
SELECT id_producto FROM producto WHERE nombre = 'LAB_CONC_TEST_BLOQUEO' ... FOR UPDATE;
SELECT pg_sleep(12);
COMMIT;
```

Sesion B (intenta bloquear, lock_timeout = 5s):
```
BEGIN;
SET LOCAL lock_timeout = '5s';
SELECT id_producto FROM producto WHERE nombre = 'LAB_CONC_TEST_BLOQUEO' ... FOR UPDATE;
```

Resultado observado: **Sesion B recibio error:** `ERROR: cancelando la sentencia debido a que se agoto el tiempo de espera de "locks"`. CONTEXTO: mientras se bloqueaba la tupla (0,4) de la relacion "producto". La transaccion de B quedo abortada.

### Limpieza final

```sql
BEGIN;
DELETE FROM detalle_pedido WHERE id_producto IN (...);
DELETE FROM producto p USING categoria c WHERE ...;
DELETE FROM categoria WHERE descripcion = 'Semilla TP2: LAB_CONC_TEST';
COMMIT;
```

Salida: `BEGIN`, `DELETE 0`, `DELETE 3`, `DELETE 1`, `COMMIT`.

### Version de PostgreSQL y nivel de aislamiento confirmado

- PostgreSQL 18.6 on x86_64-windows, compiled by msvc-19.44.35228, 64-bit
- READ COMMITTED (nivel por defecto) y REPEATABLE READ verificados con resultados coherentes.
