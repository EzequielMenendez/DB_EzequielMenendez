-- ====================================================================
-- Script de Restricciones Adicionales - Proyecto Food Store (Parte 1)
-- Reglas de negocio garantizadas a nivel de motor (Declarativas)
-- ====================================================================

BEGIN;

-- 1. Regla de negocio: La fecha y hora del pedido no puede ser futura ni anterior al lanzamiento del negocio (01/01/2026).
-- Tabla: pedido, Columna: fecha_hora
ALTER TABLE pedido
ADD CONSTRAINT chk_pedido_fecha_coherente 
CHECK (fecha_hora >= '2026-01-01 00:00:00-03' AND fecha_hora <= clock_timestamp());

-- 2. Regla de negocio: La cantidad máxima de unidades de un producto en una misma línea de pedido no puede superar las 50 unidades (control mayorista/minorista).
-- Tabla: linea_pedido, Columna: cantidad
ALTER TABLE linea_pedido
ADD CONSTRAINT chk_linea_pedido_cantidad_maxima 
CHECK (cantidad > 0 AND cantidad <= 50);

COMMIT;
