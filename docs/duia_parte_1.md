# DU/IA - Parte 1: restricciones de integridad

## Declaracion transparente

- Herramienta de IA utilizada: OpenCode / OpenAI, modelo `openai/gpt-5.6-terra`.
- Uso: asistencia para convertir requisitos de integridad en restricciones declarativas y disenar pruebas transaccionales.
- Responsabilidad del estudiante: revisar sintaxis, ejecutar en su entorno y registrar evidencia real.

## Prompt utilizado

> Implementar para un esquema PostgreSQL Food Store tres reglas: `producto.precio_lista > 0`, `btrim(producto.nombre) <> ''` y `detalle_pedido.precio_unitario > 0`. El esquema actual admite cero en los precios. Preparar un script de ALTER TABLE que no inicie una transaccion automatica, indique revision previa y sea aplicable manualmente con BEGIN/ROLLBACK. Preparar pruebas autocontenidas con categoria, cliente, producto y pedido temporales; los INSERT invalidos deben estar protegidos por SAVEPOINT y el script debe terminar en ROLLBACK.

## Aporte de IA y control humano

La IA propuso reemplazar los dos `CHECK` no negativos por `CHECK (> 0)` y agregar un `CHECK` basado en `btrim`. Tambien propuso el uso de `SAVEPOINT` seguido de `ROLLBACK TO SAVEPOINT` para que un error esperado no invalide la transaccion exterior. El estudiante debe verificar que no haya filas existentes que violen las nuevas reglas antes de confirmar los cambios.

## Verificacion real

Estado: **EJECUTADO**.

Comandos reales:

1. Consultas de revision previa sobre la base `food_store_tp2`:
   - `SELECT id_producto, precio_lista FROM producto WHERE precio_lista <= 0;` -> **0 filas** (sin violaciones).
   - `SELECT id_producto, nombre FROM producto WHERE btrim(nombre) = '';` -> **0 filas** (sin violaciones).
   - `SELECT id_pedido, id_producto, precio_unitario FROM detalle_pedido WHERE precio_unitario <= 0;` -> **0 filas** (sin violaciones).
2. Aplicacion de restricciones:
   - `ALTER TABLE producto DROP CONSTRAINT IF EXISTS ck_producto_precio_no_negativo, ADD CONSTRAINT ck_producto_precio_positivo CHECK (precio_lista > 0), ADD CONSTRAINT ck_producto_nombre_no_vacio CHECK (btrim(nombre) <> '');` -> **ALTER TABLE** exitoso.
   - `ALTER TABLE detalle_pedido DROP CONSTRAINT IF EXISTS ck_detalle_precio_no_negativo, ADD CONSTRAINT ck_detalle_precio_positivo CHECK (precio_unitario > 0);` -> **ALTER TABLE** exitoso.
3. Verificacion de existencia de las tres restricciones:
   - `SELECT conname, contype FROM pg_constraint WHERE conname IN ('ck_producto_precio_positivo', 'ck_producto_nombre_no_vacio', 'ck_detalle_precio_positivo');` -> **3 filas** devueltas, una por cada constraint.

Resultado real / errores de restricciones observados:

- **Caso valido:** INSERT de producto con nombre `'Producto valido'` y precio `10.50` -> `INSERT 0 1` (exito).
- **Error esperado 1:** INSERT de producto con precio `0` -> `ERROR: el nuevo registro para la relacion "producto" viola la restriccion "check" "ck_producto_precio_positivo"`. DETALLE: La fila que falla contiene `(2, Precio cero, null, 0.00, 0, t, 1)`.
- **Error esperado 2:** INSERT de producto con nombre `'   '` (solo espacios) -> `ERROR: el nuevo registro para la relacion "producto" viola la restriccion "check" "ck_producto_nombre_no_vacio"`. DETALLE: La fila que falla contiene `(3,    , null, 1.00, 0, t, 1)`.
- **Error esperado 3:** INSERT de detalle_pedido con precio_unitario `0` -> `ERROR: el nuevo registro para la relacion "detalle_pedido" viola la restriccion "check" "ck_detalle_precio_positivo"`. DETALLE: La fila que falla contiene `(1, 4, 2, 0.00)`.
- Todos los SAVEPOINT/ROLLBACK funcionaron correctamente. Transaccion final: `ROLLBACK`.

Fecha, base y version de PostgreSQL:

- Fecha: 2026-08-27
- Base: `food_store_tp2`
- Version: PostgreSQL 18.6 on x86_64-windows, compiled by msvc-19.44.35228, 64-bit
