# Ejercicio de Lectura Crítica — Food Store (Parte 3)

Este documento presenta el análisis crítico, el efecto real y la corrección de dos scripts generados por IA que presentaban fallas lógicas o de sintaxis que habrían provocado la destrucción o alteración indebida de datos de producción si se hubieran ejecutado sin revisión.

---

## Análisis del Script 1

### Script original suministrado
```sql
-- Generado para: dar de baja las funciones de películas retiradas de cartel
UPDATE funcion
SET activa = FALSE;
```

### 1. ¿Qué filas afectaría realmente tal como está escrito?
Afectaría y actualizaría el campo `activa` a `FALSE` en **absolutamente todas las filas** de la tabla `funcion`, sin importar si la película sigue en cartelera, si es una función futura o pasada.

### 2. ¿Por qué eso no coincide con la consigna?
La consigna solicitaba dar de baja únicamente las funciones correspondientes a **películas retiradas de cartel**. Al carecer por completo de una cláusula `WHERE`, el comando opera de manera masiva y ciega sobre todo el conjunto de datos de la tabla.

### 3. Versión corregida
Para cumplir estrictamente con la regla de negocio, se debe incorporar una cláusula `WHERE` que filtre únicamente las funciones asociadas a películas cuyo estado sea retirado o cuya fecha de exhibición haya vencido:
```sql
-- Versión corregida: Dar de baja únicamente funciones de películas retiradas de cartel
UPDATE funcion f
SET activa = FALSE
WHERE f.activa = TRUE 
  AND f.pelicula_id IN (
      SELECT p.id 
      FROM pelicula p 
      WHERE p.estado = 'RETIRADA' OR p.fecha_fin < CURRENT_DATE
  );
```

---

## Análisis del Script 2

### Script original suministrado
```sql
-- Generado para: limpiar las categorías sin productos asociados
DELETE FROM categoria
WHERE id NOT IN (SELECT categoria_id FROM producto);
```

### 1. ¿Qué filas afectaría realmente tal como está escrito?
Dependiendo de los datos, si la columna `categoria_id` en la tabla `producto` contiene **al menos un valor `NULL`**, la subconsulta `(SELECT categoria_id FROM producto)` retornará `NULL`. En SQL, la evaluación de `id NOT IN (valor1, valor2, ..., NULL)` se evalúa como `UNKNOWN` para todas las filas. Como resultado, **no se eliminará ninguna categoría (0 filas afectadas)**, fallando silenciosamente en su propósito de limpieza. Si no hubiera nulos, eliminaría las categorías huérfanas, pero es una trampa clásica de lógica SQL.

### 2. ¿Por qué eso no coincide con la consigna?
La intención era eliminar únicamente las categorías que no tienen ningún producto asociado. Sin embargo, el uso de `NOT IN` frente a posibles valores nulos en columnas de clave foránea provoca un comportamiento anómalo donde la operación no borra nada o borra incorrectamente.

### 3. Versión corregida
La forma robusta y segura de resolver esta operación en SQL es utilizando `NOT EXISTS`, que maneja correctamente la lógica de tres valores de SQL y evita los problemas de propagación de `NULL`:
```sql
-- Versión corregida: Eliminar categorías sin productos asociados utilizando NOT EXISTS (robusto ante NULLs)
DELETE FROM categoria c
WHERE NOT EXISTS (
    SELECT 1 
    FROM producto p 
    WHERE p.categoria_id = c.id
);
```
*(Alternativa con `NOT IN` asegurando la exclusión de nulos:* `WHERE id NOT IN (SELECT categoria_id FROM producto WHERE categoria_id IS NOT NULL)`*).*
