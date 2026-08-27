-- Parte 4: Consultas resumen y subconsultas
-- Verificacion de equivalencia con EXCEPT

-- Spec: Para cada categoria activa, mostrar nombre y total facturado
-- de productos vendidos, incluyendo categorias sin ventas con total 0.
-- Ordenar de mayor a menor total.

-- Version A (IA - JOIN + COALESCE)
-- (consulta_A)
SELECT c.nombre AS categoria,
       COALESCE(SUM(dp.cantidad * dp.precio_unitario), 0) AS total_facturado
FROM categoria c
LEFT JOIN producto pr ON pr.id_categoria = c.id_categoria AND pr.activo = TRUE
LEFT JOIN detalle_pedido dp ON dp.id_producto = pr.id_producto
WHERE c.activo = TRUE
GROUP BY c.nombre
ORDER BY total_facturado DESC;

-- Version B (propia - subconsulta escalar)
-- (consulta_B)
SELECT c.nombre,
       (SELECT COALESCE(SUM(dp2.cantidad * dp2.precio_unitario), 0)
        FROM producto pr2
        JOIN detalle_pedido dp2 ON dp2.id_producto = pr2.id_producto
        WHERE pr2.id_categoria = c.id_categoria AND pr2.activo = TRUE) AS total_facturado
FROM categoria c
WHERE c.activo = TRUE
ORDER BY total_facturado DESC;

-- Verificacion de equivalencia
-- Ambas deben devolver 0 filas si son equivalentes

(
  SELECT c.nombre, COALESCE(SUM(dp.cantidad * dp.precio_unitario), 0) AS total_facturado
  FROM categoria c
  LEFT JOIN producto pr ON pr.id_categoria = c.id_categoria AND pr.activo = TRUE
  LEFT JOIN detalle_pedido dp ON dp.id_producto = pr.id_producto
  WHERE c.activo = TRUE
  GROUP BY c.nombre
  ORDER BY total_facturado DESC
)
EXCEPT
(
  SELECT c.nombre,
         (SELECT COALESCE(SUM(dp2.cantidad * dp2.precio_unitario), 0)
          FROM producto pr2
          JOIN detalle_pedido dp2 ON dp2.id_producto = pr2.id_producto
          WHERE pr2.id_categoria = c.id_categoria AND pr2.activo = TRUE) AS total_facturado
  FROM categoria c
  WHERE c.activo = TRUE
  ORDER BY total_facturado DESC
);

(
  SELECT c.nombre,
         (SELECT COALESCE(SUM(dp2.cantidad * dp2.precio_unitario), 0)
          FROM producto pr2
          JOIN detalle_pedido dp2 ON dp2.id_producto = pr2.id_producto
          WHERE pr2.id_categoria = c.id_categoria AND pr2.activo = TRUE) AS total_facturado
  FROM categoria c
  WHERE c.activo = TRUE
  ORDER BY total_facturado DESC
)
EXCEPT
(
  SELECT c.nombre, COALESCE(SUM(dp.cantidad * dp.precio_unitario), 0) AS total_facturado
  FROM categoria c
  LEFT JOIN producto pr ON pr.id_categoria = c.id_categoria AND pr.activo = TRUE
  LEFT JOIN detalle_pedido dp ON dp.id_producto = pr.id_producto
  WHERE c.activo = TRUE
  GROUP BY c.nombre
  ORDER BY total_facturado DESC
);
