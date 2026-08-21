# Declaración de Uso de IA (DUIA) — Parte 1: Integridad Versionada

| Campo | Completar |
| :--- | :--- |
| **Herramienta** | OpenCode (Modelo: `google/gemini-3.5-flash-lite`) |
| **Spec o prompt utilizado** | *"Generar restricciones CHECK en SQL para la base de datos Food Store que garanticen dos reglas de negocio: 1) La fecha y hora de un pedido (`pedido.fecha_hora`) debe ser coherente (entre el 01/01/2026 y el momento actual). 2) La cantidad de unidades en una línea de pedido (`linea_pedido.cantidad`) no puede superar las 50 unidades por línea."* |
| **Qué generó** | Propuso un script DDL con `ALTER TABLE ADD CONSTRAINT CHECK` para ambas tablas, incluyendo comentarios explicativos y transacciones de prueba con `BEGIN` / `ROLLBACK`. |
| **Qué se aceptó** | Las restricciones `CHECK` con operadores lógicos estándar de PostgreSQL (`clock_timestamp()`, `>=` y `<=`, `BETWEEN` implícito). |
| **Qué se modificó o descartó, y por qué** | Se ajustó la función de tiempo de `now()` a `clock_timestamp()` en la restricción de fecha para evitar la evaluación estática al momento de crear la restricción y garantizar que evalúe el momento de la inserción, y se estructuró con bloques explícitos de `BEGIN` y `ROLLBACK` siguiendo el protocolo de seguridad. |
| **Verificación realizada** | Se ejecutaron pruebas con `INSERT` sobre la copia de trabajo:<br>1. **Válido:** Pedido con fecha actual y línea de pedido con cantidad 3 -> `INSERT 0 1` (Éxito).<br>2. **Inválido:** Línea de pedido con cantidad 55 -> Violación del constraint `chk_linea_pedido_cantidad_maxima` (Error devuelto por PostgreSQL).<br>3. **Inválido:** Pedido con fecha futura ('2030-01-01') -> Violación del constraint `chk_pedido_fecha_coherente` (Error devuelto por PostgreSQL). |
