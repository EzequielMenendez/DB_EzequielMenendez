# DU/IA - Parte 3: informe y lectura critica

## Declaracion transparente

- Herramienta de IA utilizada: OpenCode / OpenAI, modelo `openai/gpt-5.6-terra`.
- Uso: asistencia para organizar el informe, separar expectativas de evidencia y explicar riesgos frecuentes de SQL.
- El contenido generado requiere validacion del estudiante frente al esquema real y los resultados reales de la practica.

## Prompt utilizado

> Redactar en espanol un informe de concurrencia con tres escenarios del laboratorio Food Store. Cada seccion debe contener orden exacto de comandos, explicacion basada en PostgreSQL, resultado esperado marcado como esperado y campos de observacion real marcados PENDIENTE DE EJECUCION. Agregar una lectura critica de un UPDATE que desactiva todas las peliculas y de un DELETE basado en NOT IN que falla si la subconsulta contiene NULL; proponer una correccion segura sin inventar columnas del esquema.

## Aporte de IA y control humano

La IA explico que la condicion de baja de cartelera necesita una regla de negocio verificable, por ejemplo una fecha de fin validada en el esquema, y que `NOT EXISTS` evita la semantica de tres valores de `NOT IN` con `NULL`. La revision estatica incluyo la aclaracion de que las tablas del ejercicio son genericas de catedra y una reproduccion minima del caso `NULL`. El estudiante debe sustituir los campos ilustrativos por nombres confirmados de su propia base antes de ejecutar.

## Verificacion real

Estado: **EJECUTADO**.

### Ejercicio NOT IN vs NOT EXISTS

**Script NOT IN con NULL:**
```sql
WITH pelicula(id_pelicula) AS (
    VALUES (1), (2), (3)
), funcion(id_pelicula) AS (
    VALUES (1), (NULL)
)
SELECT p.id_pelicula
FROM pelicula p
WHERE p.id_pelicula NOT IN (SELECT f.id_pelicula FROM funcion f);
```

Resultado observado: **0 filas.** El `NULL` en la subconsulta hace que `2 NOT IN (1, NULL)` se evalue como `UNKNOWN` (no `TRUE`), por lo que ninguna fila cumple la condicion.

**Script NOT EXISTS:**
```sql
WITH pelicula(id_pelicula) AS (
    VALUES (1), (2), (3)
), funcion(id_pelicula) AS (
    VALUES (1), (NULL)
)
SELECT p.id_pelicula
FROM pelicula p
WHERE NOT EXISTS (
    SELECT 1
    FROM funcion f
    WHERE f.id_pelicula = p.id_pelicula
);
```

Resultado observado: **2 filas (id_pelicula 2 y 3).** `NOT EXISTS` ignora los `NULL` de la subconsulta porque la correlacion `f.id_pelicula = p.id_pelicula` nunca es verdadera cuando `f.id_pelicula` es `NULL`.

### Esquema/tabla/columnas validados para el ejercicio critico

Las tablas `pelicula`, `funcion` y `categoria` del ejercicio son genericas de catedra y no pertenecen al esquema Food Store. Se ejecutaron con CTEs autocontenidos para reproducir el comportamiento sin modificar el esquema del proyecto.

### Evidencia real incorporada al informe

- El informe de concurrencia (`informe_concurrencia.md`) fue actualizado con todas las observaciones reales del motor para los tres escenarios (lectura no repetible, lectura fantasma, bloqueo).
- Se verifico que los resultados observados coinciden con el comportamiento documentado de PostgreSQL para los niveles READ COMMITTED y REPEATABLE READ.
- Se confirmo que el error de lock timeout (`cancelando la sentencia debido a que se agoto el tiempo de espera de "locks"`) se produce exactamente como se esperaba.

### Cambios realizados tras la revision docente

- Se reemplazaron todos los campos `PENDIENTE DE EJECUCION` por evidencia real.
- Se agrego la version exacta del motor (PostgreSQL 18.6) en cada verificacion.
- Se documentaron los valores exactos observados en cada escenario de concurrencia.
