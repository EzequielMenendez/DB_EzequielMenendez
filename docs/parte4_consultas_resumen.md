# Parte 4 — Consultas resumen y subconsultas bajo especificación precisa

## Consulta 1: Total facturado por categoría vigente

### Spec

«Genera una consulta SQL sobre el esquema de Food Store que devuelva, para cada categoría vigente (`activo = TRUE`), el nombre de la categoría y el total facturado (suma de `cantidad * precio_unitario` en `detalle_pedido`) de sus productos vendidos, incluyendo las categorías sin ventas con total 0. Solo incluir productos vigentes (`activo = TRUE`). Ordenar de mayor a menor total facturado. No usar `SELECT *`.»

### Versión A (generada por IA — JOIN + COALESCE)

```sql
SELECT c.nombre AS categoria,
       COALESCE(SUM(dp.cantidad * dp.precio_unitario), 0) AS total_facturado
FROM categoria c
LEFT JOIN producto pr ON pr.id_categoria = c.id_categoria AND pr.activo = TRUE
LEFT JOIN detalle_pedido dp ON dp.id_producto = pr.id_producto
WHERE c.activo = TRUE
GROUP BY c.nombre
ORDER BY total_facturado DESC;
```

### Versión B (propia — subconsulta escalar)

```sql
SELECT c.nombre,
       (SELECT COALESCE(SUM(dp2.cantidad * dp2.precio_unitario), 0)
        FROM producto pr2
        JOIN detalle_pedido dp2 ON dp2.id_producto = pr2.id_producto
        WHERE pr2.id_categoria = c.id_categoria AND pr2.activo = TRUE) AS total_facturado
FROM categoria c
WHERE c.activo = TRUE
ORDER BY total_facturado DESC;
```

### Verificación de equivalencia

```sql
-- EXCEPT directo: ambos devuelven 0 filas
(consulta_A) EXCEPT (consulta_B);  -- 0 filas
(consulta_B) EXCEPT (consulta_A);  -- 0 filas
-- Conteo: ambas devuelven 8 filas (8 categorías activas)
```

**Resultado:** Ambas versiones son equivalentes. La subconsulta escalar evalúa una vez por fila de `categoria`, mientras que el LEFT JOIN agrupa globalmente. El orden difiere (las categorías con total 0 se ordenan entre sí de forma indefinida), pero los datos son idénticos.

---

## Consulta 2: Productos cuyo precio supera el promedio de su categoría

### Spec

«Listar productos activos cuyo precio de lista (`precio_lista`) supera el promedio de precio de su propia categoría. Mostrar: nombre del producto, precio, nombre de categoría y el promedio de la categoría. Solo productos con `activo = TRUE`. Ordenar por categoría (ASC) y precio (DESC).»

### Versión A (generada por IA — JOIN con subconsulta de promedios)

```sql
SELECT pr.nombre, pr.precio_lista, c.nombre AS categoria,
       promedio.promedio_categoria
FROM producto pr
JOIN categoria c ON c.id_categoria = pr.id_categoria
JOIN (
    SELECT id_categoria, AVG(precio_lista) AS promedio_categoria
    FROM producto
    WHERE activo = TRUE
    GROUP BY id_categoria
) promedio ON promedio.id_categoria = pr.id_categoria
WHERE pr.activo = TRUE
  AND pr.precio_lista > promedio.promedio_categoria
ORDER BY c.nombre, pr.precio_lista DESC;
```

### Versión B (propia — WHERE con subconsulta correlacionada)

```sql
SELECT pr.nombre, pr.precio_lista, c.nombre AS categoria,
       (SELECT AVG(pr2.precio_lista)
        FROM producto pr2
        WHERE pr2.id_categoria = pr.id_categoria AND pr2.activo = TRUE) AS promedio_categoria
FROM producto pr
JOIN categoria c ON c.id_categoria = pr.id_categoria
WHERE pr.activo = TRUE
  AND pr.precio_lista > (
      SELECT AVG(pr3.precio_lista)
      FROM producto pr3
      WHERE pr3.id_categoria = pr.id_categoria AND pr3.activo = TRUE
  )
ORDER BY c.nombre, pr.precio_lista DESC;
```

### Verificación de equivalencia

```sql
-- EXCEPT directo: ambos devuelven 0 filas
(consulta_A) EXCEPT (consulta_B);  -- 0 filas
(consulta_B) EXCEPT (consulta_A);  -- 0 filas
```

**Resultado:** Ambas versiones son equivalentes. La subconsulta JOIN calcula los promedios una sola vez; la subconsulta correlacionada los recalcula por cada fila de `producto`. En rendimiento, la versión JOIN es más eficiente para tablas grandes, pero los resultados son idénticos.
