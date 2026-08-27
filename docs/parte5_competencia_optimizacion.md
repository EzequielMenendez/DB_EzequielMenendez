# Parte 5 — Competencia de optimización entre equipos

## Consulta fijada por la cátedra

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

## Registro de la competencia

| Aspecto | Detalle |
|---------|---------|
| **Equipo** | Ezequiel Menéndez |
| **Base** | `food_store_tp3` (~600k filas en `detalle_pedido`) |
| **Motor** | PostgreSQL 18.6 on x86_64-windows |

### Intento 1: Sin índices adicionales (baseline)

- **Plan:** Limit → Sort → HashAggregate → Hash Join × 2 → Seq Scan (detalle_pedido, producto, categoria)
- **Tiempo real:** 350.1 ms
- **Observación:** El Seq Scan sobre 600k filas de `detalle_pedido` domina el costo (~25ms), pero el HashAggregate con 40k+ grupos consume ~190ms.

### Intento 2: Índice INCLUDE en `detalle_pedido`

- **Cambio:** `CREATE INDEX idx_detalle_producto_cantidad ON detalle_pedido (id_producto) INCLUDE (cantidad, precio_unitario)`
- **Plan:** Sin cambio de plan (el optimizador prefiere Seq Scan para agregación completa)
- **Tiempo real:** 338.6 ms
- **Mejora:** ~3% (marginal)
- **Motivo del descarte parcial:** El índice no se usa porque el GROUP BY agrupa por nombre de producto y categoría (no por `id_producto`), y el optimizador estima que un Seq Scan es más barato para procesar todas las filas.

### Intento 3: Reescritura con pre-agregación (propuesto por IA, descartado)

- **Propuesta de IA:** Crear una tabla resumen `resumen_ventas_producto` con `INSERT ... SELECT ... GROUP BY` y consultar esa tabla en vez de hacer el JOIN+GROUP BY en cada ejecución.
- **Se descartó:** Porque la especificación pide una consulta, no una tabla materializada. Además, la tabla resumen quedaría desactualizada con cada venta.

### Resultado final

| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| Tiempo real (ms) | 350.1 | 338.6 | ~3% |
| Costo estimado | 99755.54 | 99755.54 | 0% |
| Plan principal | HashAggregate + Seq Scan | Igual | Sin cambio |

**Conclusión:** Para esta consulta, los índices no mejoran significativamente el rendimiento porque el cuello de botella es el **HashAggregate** (agrupación de ~40k combinaciones producto-categoría), no el escaneo de filas. La mejora real requeriría una tabla resumen materialized o un redesign de la consulta.
