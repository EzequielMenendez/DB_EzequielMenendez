-- Parte 4 - Consulta 2
-- Spec: Listar productos activos cuyo precio supera el promedio de precio
-- de su propia categoria. Mostrar: nombre del producto, precio, categoria
-- y el promedio de la categoria. Ordenar por categoria y precio descendente.

-- Version A (IA - JOIN con subconsulta de promedios)
(
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
ORDER BY c.nombre, pr.precio_lista DESC
);

-- Version B (propia - WHERE con subconsulta correlacionada)
(
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
ORDER BY c.nombre, pr.precio_lista DESC
);

-- Verificacion de equivalencia
(
SELECT pr.nombre, pr.precio_lista, c.nombre AS categoria,
       promedio.promedio_categoria
FROM producto pr
JOIN categoria c ON c.id_categoria = pr.id_categoria
JOIN (
    SELECT id_categoria, AVG(precio_lista) AS promedio_categoria
    FROM producto WHERE activo = TRUE GROUP BY id_categoria
) promedio ON promedio.id_categoria = pr.id_categoria
WHERE pr.activo = TRUE AND pr.precio_lista > promedio.promedio_categoria
ORDER BY c.nombre, pr.precio_lista DESC
)
EXCEPT
(
SELECT pr.nombre, pr.precio_lista, c.nombre AS categoria,
       (SELECT AVG(pr2.precio_lista) FROM producto pr2
        WHERE pr2.id_categoria = pr.id_categoria AND pr2.activo = TRUE) AS promedio_categoria
FROM producto pr
JOIN categoria c ON c.id_categoria = pr.id_categoria
WHERE pr.activo = TRUE
  AND pr.precio_lista > (SELECT AVG(pr3.precio_lista) FROM producto pr3
                          WHERE pr3.id_categoria = pr.id_categoria AND pr3.activo = TRUE)
ORDER BY c.nombre, pr.precio_lista DESC
);

(
SELECT pr.nombre, pr.precio_lista, c.nombre AS categoria,
       (SELECT AVG(pr2.precio_lista) FROM producto pr2
        WHERE pr2.id_categoria = pr.id_categoria AND pr2.activo = TRUE) AS promedio_categoria
FROM producto pr
JOIN categoria c ON c.id_categoria = pr.id_categoria
WHERE pr.activo = TRUE
  AND pr.precio_lista > (SELECT AVG(pr3.precio_lista) FROM producto pr3
                          WHERE pr3.id_categoria = pr.id_categoria AND pr3.activo = TRUE)
ORDER BY c.nombre, pr.precio_lista DESC
)
EXCEPT
(
SELECT pr.nombre, pr.precio_lista, c.nombre AS categoria,
       promedio.promedio_categoria
FROM producto pr
JOIN categoria c ON c.id_categoria = pr.id_categoria
JOIN (
    SELECT id_categoria, AVG(precio_lista) AS promedio_categoria
    FROM producto WHERE activo = TRUE GROUP BY id_categoria
) promedio ON promedio.id_categoria = pr.id_categoria
WHERE pr.activo = TRUE AND pr.precio_lista > promedio.promedio_categoria
ORDER BY c.nombre, pr.precio_lista DESC
);
