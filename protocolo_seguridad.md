# Protocolo de Seguridad — Food Store (PostgreSQL)

Este documento establece los procedimientos obligatorios de seguridad para la manipulación, modificación y pruebas sobre la base de datos del proyecto integrador **Food Store**, cumpliendo con los tres pilares definidos por la cátedra: **Copia**, **Transacción** y **Respaldo**.

---

## 1. Copia (Aislamiento de Entorno)
Nunca se realizan pruebas experimentales, cambios estructurales ni ejecución de scripts generados sobre bases de producción o bases con datos definitivos.
- **Comando de creación de copia de trabajo en PostgreSQL:**
  ```sql
  -- Desconectar usuarios activos si es necesario y crear la copia basada en la plantilla de desarrollo
  CREATE DATABASE food_store_copia WITH TEMPLATE food_store;
  ```
- **Uso:** Todas las pruebas de restricciones, triggers y scripts de migración se ejecutan exclusivamente sobre `food_store_copia`.

---

## 2. Transacción (Inspección Previa)
Ningún script de modificación de datos o aplicación de lógica corre de forma directa sin antes ser validado de forma transaccional.
- **Estructura obligatoria para scripts de escritura o pruebas:**
  ```sql
  BEGIN;
  
  -- Sentencias de prueba (INSERT, UPDATE, DELETE, ALTER, etc.)
  
  -- Inspección de filas afectadas y resultados
  SELECT * FROM tabla_afectada;
  
  -- Si el resultado es correcto y esperado: COMMIT;
  -- Si hay errores o efectos colaterales no deseados: ROLLBACK;
  ROLLBACK;
  ```
- **Uso:** Permite verificar filas afectadas, mensajes y restricciones antes de confirmar cualquier cambio definitivo.

---

## 3. Respaldo (Seguridad Estructural)
Antes de aplicar cualquier cambio estructural mayor en la base de datos (como `ALTER TABLE`, `DROP`, migraciones complejas o aplicación masiva de restricciones), se debe generar un respaldo binario independiente de la copia de trabajo.
- **Comando de respaldo con `pg_dump`:**
  ```bash
  pg_dump -U postgres -d food_store_copia -F c -b -v -f "C:\Users\ezeme\OneDrive\Desktop\BD_EzequielMenendez\backup_food_store_copia.backup"
  ```
- **Restauración en caso de fallo crítico:**
  ```bash
  pg_restore -U postgres -d food_store_copia -v "C:\Users\ezeme\OneDrive\Desktop\BD_EzequielMenendez\backup_food_store_copia.backup"
  ```

---
*Aprobado y aplicado para todas las iteraciones de desarrollo en Food Store.*
