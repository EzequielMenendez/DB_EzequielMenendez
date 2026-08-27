# Parte 3 — Lectura crítica de planes interpretados por IA

Plan analizado: **Consulta 1 después de optimizar** (ILIKE + precio con índice GIN trigram).

## Plan real de EXPLAIN ANALYZE

```
Sort  (cost=109.83..109.84 rows=3 width=32) (actual time=1.953..1.955 rows=81.00 loops=1)
  Sort Key: precio_lista DESC
  Sort Method: quicksort  Memory: 29kB
  Buffers: shared hit=132
  ->  Bitmap Heap Scan on producto  (cost=90.98..109.81 rows=3 width=32) (actual time=1.834..1.904 rows=81.00 loops=1)
        Recheck Cond: ((nombre)::text ~~* '%producto 123%'::text)
        Rows Removed by Index Recheck: 1
        Filter: ((precio_lista >= '1000'::numeric) AND (precio_lista <= '4000'::numeric))
        Rows Removed by Filter: 30
        Heap Blocks: exact=6
        Buffers: shared hit=129
        ->  Bitmap Index Scan on idx_producto_nombre_trgm  (cost=0.00..90.98 rows=5 width=0) (actual time=1.814..1.814 rows=112.00 loops=1)
              Index Cond: ((nombre)::text ~~* '%producto 123%'::text)
              Index Searches: 1
              Buffers: shared hit=123
Planning Time: 2.804 ms
Execution Time: 2.339 ms
```

## Explicación generada por IA (prompt: "Explicá este plan nodo por nodo")

> **Sort:** El plan ordena los resultados por `precio_lista` de mayor a menor usando quicksort, consumiendo 29kB de memoria.
>
> **Bitmap Heap Scan:** Realiza un escaneo de heap usando un bitmap generado por el índice GIN trigram. El filtro `ILIKE '%producto 123%'` se resuelve a nivel de índice, y luego se aplica un filtro adicional de precio (`BETWEEN 1000 AND 4000`) sobre las filas recuperadas.
>
> **Bitmap Index Scan:** El índice GIN trigram encuentra 112 filas que coinciden con el patrón de nombre. El costo estimado es de 90.98.
>
> **Resultado:** El plan ejecuta en 2.339 ms, escaneando 132 buffers en memoria. El costo total estimado es 109.83.

## Tabla de contrastación

| Afirmación de la IA | ¿Correcta? | Corrección / evidencia del plan real |
|----------------------|-------------|--------------------------------------|
| "El plan ordena por quicksort con 29kB de memoria" | Sí | Confirmado: `Sort Method: quicksort Memory: 29kB` |
| "El filtro ILIKE se resuelve a nivel de índice" | **Parcial** | El índice GIN resuelve el patrón de nombre, pero el plan muestra `Recheck Cond` en el Bitmap Heap Scan, lo que significa que el motor verifica cada candidato del índice contra el heap real. La IA ignora que hay un recheck post-índice. |
| "El filtro de precio se aplica sobre las filas recuperadas" | Sí | Confirmado: `Filter: ((precio_lista >= 1000) AND (precio_lista <= 4000))` con `Rows Removed by Filter: 30`. |
| "El índice GIN encuentra 112 filas" | Sí | Confirmado: `rows=112.00` en el Bitmap Index Scan. |
| "El costo estimado es 90.98 para el Bitmap Index Scan" | Sí | Confirmado: `(cost=0.00..90.98 rows=5 width=0)`. |
| "El plan escanea 132 buffers" | Sí | Confirmado: `Buffers: shared hit=132` en el nodo Sort (acumula los hijos). |
| "La IA no menciona que solo 81 de 112 filas del índice sobreviven al filtro de precio" | **Imprecisión** | La IA dice que el índice encuentra 112 filas pero no aclara que el filtro de precio descarta 30 de ellas (112 - 30 - 1 recheck = 81). Esto es relevante porque muestra que el índice GIN no filtra por precio, solo por nombre. |
| "La IA confunde cost estimado con tiempo real" | **No en este caso** | La IA correctamente distingue costo (109.83) de tiempo real (2.339 ms). En otros planes la IA suele confundirlos, pero aquí fue precisa. |
| "Rows Removed by Index Recheck: 1" | **La IA no lo menciona** | El plan muestra que 1 fila fue eliminada durante el recheck del bitmap (el bitmap puede marcar falsos positivos). La IA debería explicar que el Bitmap Heap Scan hace un recheck contra el heap para confirmar que la fila realmente cumple la condición del índice. |

## Conclusiones

La IA generó una explicación mayormente correcta pero con dos omisiones relevantes:
1. **No explicó el mecanismo de recheck** del Bitmap Heap Scan, que es fundamental para entender por qué el plan usa un bitmap en vez de un Index Scan directo.
2. **No cuantificó la filtración post-índice** (30 filas descartadas por precio de 112 candidatas), lo que habría demostrado que el índice GIN solo resuelve la parte de nombre, no la de precio.
