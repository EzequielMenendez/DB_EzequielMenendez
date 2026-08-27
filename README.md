# BDII - Food Store (Base de Datos II)

Entrega académica para el curso de Base de Datos II. Sistema de gestión de una tienda de alimentos con PostgreSQL.

## Estructura del proyecto

```
├── db/
│   ├── schema.sql              # Esquema base del proyecto
│   ├── sql/                    # Scripts SQL organizados por práctica
│   └── backups/                # Respaldos (NO versionar)
├── docs/                       # Documentación y entregables
├── src/                        # Código fuente (futuro)
├── .kiro/steering/             # Reglas de Kiro
│   └── security-policies.md    # Normas de seguridad
├── .gitignore
├── .env.example                # Variables de entorno (sin valores reales)
├── AGENTS.md                   # Contexto del proyecto para OpenCode
└── README.md
```

## Entregas realizadas

### Semana 2 - Integridad y Concurrencia
- `db/schema.sql`: esquema base del proyecto.
- `docs/protocolo_seguridad.md`: creación segura de bases, respaldos y uso transaccional.
- `db/sql/01_restricciones_integridad.sql`: restricciones de integridad revisadas.
- `db/sql/02_pruebas_restricciones.sql`: pruebas válidas e inválidas reversibles.
- `db/sql/03_laboratorio_concurrencia.sql`: procedimientos para dos sesiones.
- `docs/informe_concurrencia.md`: informe con evidencia real del motor.
- `docs/ejercicio_lectura_critica.md`: análisis de dos patrones SQL riesgosos.
- `docs/duia_parte_*.md`: declaraciones de uso de IA.

## Requisitos previos

- PostgreSQL 18.x con `psql`, `createdb`, `pg_dump` y `pg_restore` en `PATH`.
- Git y GitHub Desktop instalados.
- OpenCode y Kiro configurados.
- Dos terminales independientes para la práctica de concurrencia.
