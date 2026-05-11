# Diccionario de Datos
## Proyecto: TechStoreIntelligentSystem

---

# MÓDULO 1 — CATÁLOGO

## Tabla: categoria

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_categoria | BIGSERIAL | PK | Identificador único |
| nombre | VARCHAR(100) | NOT NULL, UNIQUE | Nombre categoría |
| descripcion | TEXT | NULL | Descripción |
| estado | BOOLEAN | DEFAULT TRUE | Estado lógico |

---

## Tabla: producto

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_producto | BIGSERIAL | PK | Identificador producto |
| id_categoria | BIGINT | FK | Categoría |
| id_marca | BIGINT | FK | Marca |
| nombre | VARCHAR(150) | NOT NULL | Nombre producto |
| descripcion | TEXT | NULL | Descripción |
| sku | VARCHAR(50) | UNIQUE | SKU producto |

---

## Tabla: variante

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_variante | BIGSERIAL | PK | Identificador variante |
| id_producto | BIGINT | FK | Producto asociado |
| color | VARCHAR(50) | NULL | Color |
| almacenamiento | VARCHAR(50) | NULL | Capacidad |
| memoria_ram | VARCHAR(50) | NULL | RAM |
| precio_base | NUMERIC(12,2) | CHECK(precio_base > 0) | Precio |

---

# MÓDULO 2 — INVENTARIO

## Tabla: almacen

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_almacen | BIGSERIAL | PK | Identificador almacén |
| nombre | VARCHAR(100) | NOT NULL | Nombre |
| ubicacion | VARCHAR(255) | NULL | Ubicación |

---

## Tabla: stock

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_stock | BIGSERIAL | PK | Identificador stock |
| id_variante | BIGINT | FK | Variante |
| id_almacen | BIGINT | FK | Almacén |
| cantidad | INTEGER | DEFAULT 0 | Cantidad |

---

# MÓDULO 3 — USUARIOS

## Tabla: usuario

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_usuario | BIGSERIAL | PK | Identificador |
| nombre | VARCHAR(100) | NOT NULL | Nombre |
| email | VARCHAR(150) | UNIQUE | Correo |
| password_hash | VARCHAR(255) | NOT NULL | Contraseña |

---

## Tabla: cliente

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_cliente | BIGSERIAL | PK | Identificador |
| id_usuario | BIGINT | FK | Usuario |
| fecha_registro | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Registro |

---

# MÓDULO 4 — ÓRDENES

## Tabla: orden

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_orden | BIGSERIAL | PK | Identificador |
| id_cliente | BIGINT | FK | Cliente |
| total | NUMERIC(12,2) | NOT NULL | Total |
| estado | VARCHAR(50) | NOT NULL | Estado |

---

## Tabla: detalle_orden

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_detalle | BIGSERIAL | PK | Identificador |
| id_orden | BIGINT | FK | Orden |
| id_variante | BIGINT | FK | Variante |
| cantidad | INTEGER | NOT NULL | Cantidad |

---

# MÓDULO 5 — PAGOS

## Tabla: metodo_pago

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_metodo_pago | BIGSERIAL | PK | Identificador |
| nombre | VARCHAR(100) | NOT NULL | Método |

---

## Tabla: transaccion

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_transaccion | BIGSERIAL | PK | Identificador |
| id_orden | BIGINT | FK | Orden |
| monto | NUMERIC(12,2) | NOT NULL | Monto |

---
