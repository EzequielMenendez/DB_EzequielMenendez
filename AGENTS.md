# AGENTS.md - Food Store (Base de Datos II)

## Proyecto

Base de datos relacional para un sistema de gestión de tienda de alimentos (Food Store). Desarrollado en el marco del curso de Base de Datos II.

## Stack tecnológico

- **Motor de base de datos:** PostgreSQL 18.x
- **Lenguaje:** SQL (DDL, DML, DCL)
- **Herramientas:** psql, pg_dump, pg_restore, createdb
- **Control de versiones:** Git + GitHub Desktop
- **Planificación:** Kiro (specs)
- **Asistente de código:** OpenCode

## Estructura del proyecto

```
BD_EzequielMenendez/
├── db/
│   ├── schema.sql           # Esquema base del proyecto
│   ├── sql/                 # Scripts SQL organizados por práctica
│   │   ├── 01_restricciones_integridad.sql
│   │   ├── 02_pruebas_restricciones.sql
│   │   ├── 03_laboratorio_concurrencia.sql
│   │   └── 04_carga_masiva.sql
│   └── backups/             # Respaldos (.dump) - NO versionar
├── docs/                    # Documentación y entregables
│   ├── protocolo_seguridad.md
│   ├── informe_concurrencia.md
│   ├── ejercicio_lectura_critica.md
│   └── duia_parte_*.md
├── src/                     # Código fuente (futuro)
├── .kiro/steering/
│   └── security-policies.md # Normas de seguridad
├── .gitignore
├── .env.example
├── AGENTS.md                # Este archivo
└── README.md
```

## Comandos útiles

```bash
# Crear base de datos
createdb -U postgres food_store

# Cargar esquema
psql -U postgres -d food_store -f db/schema.sql

# Respaldar
pg_dump -U postgres -Fc -f db/backups/food_store.dump food_store

# Restaurar
createdb -U postgres food_store_restaurada
pg_restore -U postgres -d food_store_restaurada db/backups/food_store.dump
```

## Convenciones

- Los scripts SQL van en `db/sql/` numerados secuencialmente.
- Los entregables académicos van en `docs/`.
- Los backups nunca se versionan (están en `.gitignore`).
- Cada práctica se commitea de forma independiente con mensajes descriptivos.

## Seguridad

Respetar siempre las normas definidas en
`.kiro/steering/security-policies.md`.
