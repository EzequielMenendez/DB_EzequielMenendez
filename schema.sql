-- Borrado de tablas para crear desde cero
DROP TABLE IF EXISTS linea_pedido;
DROP TABLE IF EXISTS pedido;
DROP TABLE IF EXISTS producto;
DROP TABLE IF EXISTS cliente;
DROP TABLE IF EXISTS categoria;
DROP TYPE IF EXISTS forma_pago;

-- Formas de pago
CREATE TYPE forma_pago AS ENUM ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA');

-- Tabla categoria
CREATE TABLE categoria (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre      VARCHAR(80)   NOT NULL UNIQUE,
    descripcion VARCHAR(255),
    activo      BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- Tabla producto
CREATE TABLE producto (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre       VARCHAR(120)  NOT NULL,
    descripcion  VARCHAR(255),
    precio       NUMERIC(10,2) NOT NULL CHECK (precio >= 0),
    stock        INTEGER       NOT NULL DEFAULT 0 CHECK (stock >= 0),
    activo       BOOLEAN       NOT NULL DEFAULT TRUE,
    -- ON DELETE RESTRICT: Regla R7 (no eliminar físicamente productos ni categorías dados de baja para preservar el historial).
    categoria_id BIGINT        NOT NULL REFERENCES categoria (id) ON DELETE RESTRICT,
    created_at   TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- Tabla cliente
CREATE TABLE cliente (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre     VARCHAR(80)   NOT NULL,
    apellido   VARCHAR(80)   NOT NULL,
    email      VARCHAR(160)  NOT NULL UNIQUE,
    telefono   VARCHAR(30),
    direccion  VARCHAR(255),
    activo     BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- Tabla pedido
CREATE TABLE pedido (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fecha_hora TIMESTAMPTZ NOT NULL DEFAULT now(),
    forma_pago forma_pago  NOT NULL DEFAULT 'EFECTIVO',
    -- ON DELETE RESTRICT: Evita eliminar clientes que tienen pedidos asociados (integridad histórica).
    cliente_id BIGINT      NOT NULL REFERENCES cliente (id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Tabla Linea pedido que funciona como intermedia con pedido y producto
CREATE TABLE linea_pedido (
    -- ON DELETE CASCADE: Si se elimina el pedido, se eliminan sus líneas de detalle asociadas.
    pedido_id       BIGINT        NOT NULL REFERENCES pedido (id)   ON DELETE CASCADE,
    -- ON DELETE RESTRICT: Evita eliminar productos que forman parte de pedidos históricos/facturados.
    producto_id     BIGINT        NOT NULL REFERENCES producto (id) ON DELETE RESTRICT,
    cantidad        INTEGER       NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(10,2) NOT NULL CHECK (precio_unitario >= 0),
    PRIMARY KEY (pedido_id, producto_id)
);

-- Creación de indices
-- mostrar todos los pedidos de un cliente.
CREATE INDEX idx_pedido_cliente ON pedido (cliente_id);

-- listar productos vigentes de una categoria.
CREATE INDEX idx_producto_categoria ON producto (categoria_id) WHERE activo;

-- cuanto se vendio de cada producto.
CREATE INDEX idx_linea_producto ON linea_pedido (producto_id);
