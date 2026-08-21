# Declaración de Uso de IA (DUIA) — Parte 2: Laboratorio de Concurrencia

| Campo | Completar |
| :--- | :--- |
| **Herramienta** | OpenCode (Modelo: `google/gemini-3.5-flash-lite`) |
| **Spec o prompt utilizado** | *"Explicar qué ocurre en PostgreSQL al ejecutar dos sesiones concurrentes bajo escenarios de espera por bloqueo (`FOR UPDATE`), lectura no repetible en `READ COMMITTED` vs `REPEATABLE READ`, y detección de interbloqueos (`DEADLOCK` código 40P01)."* |
| **Qué generó** | Explicaciones conceptuales detalladas sobre el comportamiento de bloqueos a nivel de tupla, MVCC (*Multi-Version Concurrency Control*) y el funcionamiento del detector de interbloqueos (*deadlock detector*) en PostgreSQL. |
| **Qué se aceptó** | Las explicaciones teóricas sobre los mecanismos internos del motor y los comandos SQL específicos para simular cada anomalía. |
| **Qué se modificó o descartó, y por qué** | Se adaptaron los comandos de ejemplo genéricos provistos por la IA para que utilicen las tablas y IDs reales de nuestro esquema `producto` (`id = 1`, `id = 2`) del proyecto Food Store. |
| **Verificación realizada** | Se reprodujeron los tres escenarios en dos pestañas de terminal con `psql` conectadas a la base de trabajo `food_store`, confirmando que el motor de PostgreSQL responde exactamente con los bloqueos, valores dinámicos y el error de deadlock (`40P01`) descritos. |
