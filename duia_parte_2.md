# DU/IA - Parte 2: concurrencia

## Declaracion transparente

- Herramienta de IA utilizada: OpenCode / OpenAI, modelo `openai/gpt-5.6-terra`.
- Uso: asistencia para redactar procedimientos coordinados de dos sesiones sobre el esquema Food Store.
- No se atribuyen a la IA ni al estudiante resultados de motor que no hayan sido capturados durante una ejecucion real.

## Prompt utilizado

> Diseñar un laboratorio PostgreSQL para pegar manualmente en dos sesiones `psql` sobre Food Store. Incluir semilla y limpieza controladas, una lectura no repetible del precio de un producto comparando READ COMMITTED y REPEATABLE READ, una lectura fantasma contando productos activos con ambos niveles y una espera de bloqueo mediante SELECT FOR UPDATE. No fabricar salidas: indicar el orden exacto de las sentencias y distinguir comportamiento esperado de observacion real.

## Aporte de IA y control humano

La IA estructuro los bloques por sesion y aislamiento. La revision estatica incluyo el marcador unico compartido por ambas sesiones, filtros por la descripcion exacta de la semilla, limpieza transaccional y el limite de espera de bloqueo de diez segundos. El estudiante debe coordinar los puntos de espera, capturar las salidas y comprobar que la limpieza final se haya ejecutado.

## Verificacion real

Estado actual: **PENDIENTE DE EJECUCION**. La revision estatica incluyo los cambios de seguridad indicados; no hubo dos sesiones PostgreSQL ejecutadas ni resultados capturados.

Completar despues de ejecutar:

```text
Comandos reales por sesion:
Salidas reales y tiempos de espera observados:
Version de PostgreSQL y nivel de aislamiento confirmado:
```
