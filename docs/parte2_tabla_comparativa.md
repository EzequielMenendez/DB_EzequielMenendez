# Parte 2 — Tabla comparativa de optimización

Base: `food_store_tp3` (PostgreSQL 18.6, ~600k filas en detalle_pedido).

## Consulta 1: Búsqueda de productos por nombre (ILIKE) y rango de precio

```sql
SELECT id_producto, nombre, precio_lista, stock
FROM producto
WHERE nombre ILIKE '%producto 123%'
  AND precio_lista BETWEEN 1000 AND 4000
ORDER BY precio_lista DESC;
```

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Nodo raíz** | Sort → Seq Scan | Sort → Bitmap Heap Scan |
| **Costo estimado** | 1589.02 | 109.83 |
| **Tiempo real** | **18.640 ms** | **2.339 ms** |
| **Filas descartadas por filtro** | 49919 (Seq Scan total) | 30 (solo post-index) |
| **Buffers shared hit** | 717 | 132 |
| **Cambio aplicado** | — | `CREATE INDEX idx_producto_nombre_trgm ON producto USING gin (nombre gin_trgm_ops)` |
| **Mejora** | — | **8x más rápido** |

**Justificación:** ILIKE con `%` al inicio no puede usar un B-tree estándar. El índice GIN con `pg_trgm` permite buscar subcadenas directamente, reduciendo las filas escaneadas de 50.000 a 112 antes del filtro de precio.

---

## Consulta 2: Pedidos por forma de pago y rango de fechas, con total facturado

```sql
SELECT p.id_pedido, p.fecha, p.forma_pago,
       sum(dp.cantidad * dp.precio_unitario) AS total_pedido
FROM pedido p
JOIN detalle_pedido dp ON dp.id_pedido = p.id_pedido
WHERE p.forma_pago = 'TARJETA'
  AND p.fecha >= '2026-01-01'
GROUP BY p.id_pedido, p.fecha, p.forma_pago
ORDER BY total_pedido DESC
LIMIT 20;
```

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Nodo raíz** | Limit → Sort → HashAggregate → Hash Join → Seq Scan(pedido) + Seq Scan(detalle) | Limit → Sort → HashAggregate → Hash Join → Bitmap Scan(pedido) + Seq Scan(detalle) |
| **Costo estimado** | 31659.25 | 30580.99 |
| **Tiempo real** | **179.388 ms** | **175.863 ms** |
| **Filas descartadas en pedido** | 156232 | 0 (usa índice) |
| **Buffers shared hit** | 5886 | 5886 + read=170 |
| **Cambio aplicado** | — | `CREATE INDEX idx_pedido_forma_pago_fecha ON pedido (forma_pago, fecha DESC)` |
| **Mejora** | — | **~2% (marginal)** |

**Justificación:** El índice en `pedido(forma_pago, fecha)` permite un Bitmap Index Scan en vez de Seq Scan, eliminando las 156k filas descartadas. Sin embargo, el costo dominante es el HashAggregate sobre 43k pedidos y el Seq Scan de 600k filas en `detalle_pedido`, por lo que la mejora global es pequeña. Para una mejora mayor se necesitaría un índice cubriente en `detalle_pedido` o un红化 de la agregación.

---

## Consulta 3: Top 20 productos más vendidos con categoría

```sql
SELECT pr.nombre AS producto, c.nombre AS categoria,
       sum(dp.cantidad) AS unidades_vendidas,
       sum(dp.cantidad * dp.precio_unitario) AS monto_total
FROM detalle_pedido dp
JOIN producto pr ON pr.id_producto = dp.id_producto
JOIN categoria c ON c.id_categoria = pr.id_categoria
GROUP BY pr.nombre, c.nombre
ORDER BY monto_total DESC
LIMIT 20;
```

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Nodo raíz** | Limit → Sort → HashAggregate → Hash Join × 2 → Seq Scan(detalle) | Igual (sin cambio de plan) |
| **Costo estimado** | 99755.54 | 99755.54 |
| **Tiempo real** | **350.139 ms** | **338.628 ms** |
| **Filas totales escaneadas** | 600000 (Seq Scan detalle) | 600000 (Seq Scan detalle) |
| **Buffers shared hit** | 5130 | 5130 |
| **Cambio aplicado** | — | `CREATE INDEX idx_detalle_producto_cantidad ON detalle_pedido (id_producto) INCLUDE (cantidad, precio_unitario)` |
| **Mejora** | — | **~3% (marginal)** |

**Justificación:** El plan no cambia porque el optimizador prefiere Seq Scan sobre 600k filas para una agregación completa (hash aggregate). El índice INCLUDE no se usa porque el GROUP BY agrupa por `pr.nombre, c.nombre` (40k combinaciones posibles), lo que hace que el HashAggregate sea el nodo dominante (~190ms de los 338ms totales). Para mejorar significativamente se necesitaría una tabla resumen materializada o una reescritura de la consulta con pre-agregación.

---

## Resumen de mejoras

| Consulta | Antes (ms) | Después (ms) | Mejora | Índice aplicado |
|----------|-----------|-------------|--------|-----------------|
| 1. ILIKE + precio | 18.6 | 2.3 | **8x** | GIN trigram en `producto.nombre` |
| 2. Forma pago + fecha | 179.4 | 175.9 | ~2% | B-tree en `pedido(forma_pago, fecha)` |
| 3. Top productos + categoría | 350.1 | 338.6 | ~3% | INCLUDE en `detalle_pedido(id_producto)` |
