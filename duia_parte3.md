# Declaración de Uso de IA (DUIA) — Parte 3: Lectura Crítica

| Campo | Completar |
| :--- | :--- |
| **Herramienta** | OpenCode / Análisis Crítico Humano sobre propuesta de IA |
| **Spec o prompt utilizado** | *"Analizar el impacto y riesgos de ejecución de dos scripts SQL generados para mantenimiento: un UPDATE masivo sin WHERE y un DELETE con operador NOT IN potencialmente vulnerable a propagación de NULL."* |
| **Qué generó** | Los scripts originales con supuestas intenciones de mantenimiento de base de datos (`UPDATE funcion SET activa = FALSE` y `DELETE FROM categoria WHERE id NOT IN (...)`). |
| **Qué se aceptó** | Ninguno de los scripts originales se aceptó para ejecución directa debido a su naturaleza destructiva o defectuosa. |
| **Qué se modificó o descartó, y por qué** | Se descartó el `UPDATE` masivo por carecer de filtro `WHERE` (lo que habría desactivado todas las funciones del sistema) y se reescribió incorporando condiciones específicas. Se descartó el uso de `NOT IN` puro en el `DELETE` debido a la vulnerabilidad lógica ante valores `NULL` y se reemplazó por la construcción robusta `NOT EXISTS`. |
| **Verificación realizada** | Análisis estricto de la lógica de tres valores de SQL (True/False/Unknown) frente a subconsultas con nulos y validación de alcance de actualización relacional. |
