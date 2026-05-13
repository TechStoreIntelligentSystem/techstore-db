-- =====================================================
-- TechStoreIntelligentSystem - DDL Scripts
-- Database: PostgreSQL 14+
-- Design: 3NF Normalized, Liquibase Compatible
-- Language: English, Singular Names
-- Audit: Complete tracking with audit_log table
-- TABLAS: 54 ENTIDADES
-- =====================================================

CREATE SCHEMA IF NOT EXISTS techstore;
SET SCHEMA 'techstore';

-- =====================================================
-- ENUMS
-- =====================================================
CREATE TYPE product_status AS ENUM ('Active', 'Inactive', 'Discontinued');
CREATE TYPE user_status AS ENUM ('Active', 'Inactive', 'Blocked');
CREATE TYPE order_status AS ENUM ('Pending', 'Confirmed', 'Preparing', 'Shipped', 'Delivered', 'Cancelled');
CREATE TYPE payment_status AS ENUM ('Pending', 'Processed', 'Approved', 'Rejected', 'Cancelled', 'Refunded');
CREATE TYPE document_type AS ENUM ('CC', 'TI', 'PP', 'CE', 'NIT');
CREATE TYPE client_type AS ENUM ('Natural', 'Corporate');
CREATE TYPE address_type AS ENUM ('Residence', 'Work', 'Other');
CREATE TYPE phone_type AS ENUM ('Mobile', 'Fixed', 'Commercial');
CREATE TYPE discount_type AS ENUM ('Percentage', 'Amount');
CREATE TYPE payment_method_type AS ENUM ('Credit Card', 'Debit Card', 'Transfer', 'Cash', 'E-Wallet', 'Other');
CREATE TYPE movement_type AS ENUM ('Entry', 'Exit', 'Adjustment', 'Transfer');
CREATE TYPE receipt_status AS ENUM ('Pending', 'Partial', 'Complete');
CREATE TYPE return_status AS ENUM ('Requested', 'Approved', 'Rejected', 'In Transit', 'Received', 'Processed', 'Refunded');
CREATE TYPE return_condition AS ENUM ('Like New', 'Used', 'Defective', 'Incomplete');
CREATE TYPE order_detail_status AS ENUM ('Pending', 'Preparing', 'Shipped', 'Delivered', 'Cancelled');
CREATE TYPE shipping_status AS ENUM ('Pending', 'In Transit', 'Delivered', 'Not Delivered', 'Returned');
CREATE TYPE operation_type AS ENUM ('INSERT', 'UPDATE', 'DELETE', 'SELECT');
CREATE TYPE alert_severity AS ENUM ('Low', 'Medium', 'High', 'Critical');
CREATE TYPE suspicious_status AS ENUM ('Detected', 'Investigated', 'Resolved', 'False Alarm');
CREATE TYPE session_status AS ENUM ('Active', 'Closed', 'Expired');
CREATE TYPE role_status AS ENUM ('Active', 'Inactive');
CREATE TYPE permission_status AS ENUM ('Active', 'Inactive');
CREATE TYPE cart_status AS ENUM ('Active', 'Abandoned', 'Converted');

-- =====================================================
-- TABLA 1-9: USER & SECURITY MODULE
-- =====================================================

-- 1. user
CREATE TABLE user (
    id_user SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(200),
    status user_status NOT NULL DEFAULT 'Active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP,
    failed_attempts INT DEFAULT 0,
    last_password_change TIMESTAMP,
    must_change_password BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_user_email ON user(email);
CREATE INDEX idx_user_status ON user(status);

-- 2. role
CREATE TABLE role (
    id_role SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    access_level INT CHECK (access_level >= 1 AND access_level <= 10),
    status role_status NOT NULL DEFAULT 'Active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. permission
CREATE TABLE permission (
    id_permission SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    module VARCHAR(100),
    action VARCHAR(50),
    resource VARCHAR(100),
    status permission_status NOT NULL DEFAULT 'Active'
);

-- 4. role_permission
CREATE TABLE role_permission (
    id_role INT NOT NULL REFERENCES role(id_role) ON DELETE CASCADE,
    id_permission INT NOT NULL REFERENCES permission(id_permission) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_role, id_permission)
);

-- 5. user_role
CREATE TABLE user_role (
    id_user_role SERIAL PRIMARY KEY,
    id_user INT NOT NULL REFERENCES user(id_user) ON DELETE CASCADE,
    id_role INT NOT NULL REFERENCES role(id_role) ON DELETE CASCADE,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expiration_date TIMESTAMP,
    status user_status NOT NULL DEFAULT 'Active',
    assigned_by VARCHAR(150),
    reason TEXT,
    UNIQUE(id_user, id_role)
);
CREATE INDEX idx_user_role_user ON user_role(id_user);

-- 6. session
CREATE TABLE session (
    id_session SERIAL PRIMARY KEY,
    id_user INT NOT NULL REFERENCES user(id_user) ON DELETE CASCADE,
    session_token VARCHAR(500) NOT NULL UNIQUE,
    ip_address VARCHAR(45),
    browser VARCHAR(255),
    device VARCHAR(100),
    started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_accessed_at TIMESTAMP,
    closed_at TIMESTAMP,
    status session_status NOT NULL DEFAULT 'Active',
    close_reason VARCHAR(255)
);
CREATE INDEX idx_session_user ON session(id_user);
CREATE INDEX idx_session_token ON session(session_token);

-- 7. audit_log
CREATE TABLE audit_log (
    id_audit SERIAL PRIMARY KEY,
    id_user INT REFERENCES user(id_user) ON DELETE SET NULL,
    operation operation_type NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    record_id INT,
    old_values JSON,
    new_values JSON,
    executed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    browser VARCHAR(255),
    result VARCHAR(50) DEFAULT 'Success',
    error_message TEXT
);
CREATE INDEX idx_audit_log_user ON audit_log(id_user);
CREATE INDEX idx_audit_log_table ON audit_log(table_name);
CREATE INDEX idx_audit_log_executed_at ON audit_log(executed_at);

-- 8. suspicious_activity
CREATE TABLE suspicious_activity (
    id_activity SERIAL PRIMARY KEY,
    id_user INT REFERENCES user(id_user) ON DELETE SET NULL,
    alert_type VARCHAR(100),
    description TEXT,
    ip_address VARCHAR(45),
    browser VARCHAR(255),
    severity alert_severity NOT NULL DEFAULT 'Medium',
    status suspicious_status NOT NULL DEFAULT 'Detected',
    detected_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    investigated_at TIMESTAMP,
    investigator VARCHAR(150),
    actions_taken TEXT,
    investigation_result VARCHAR(255)
);
CREATE INDEX idx_suspicious_activity_user ON suspicious_activity(id_user);
CREATE INDEX idx_suspicious_activity_severity ON suspicious_activity(severity);

-- 9. attribute (NUEVA)
CREATE TABLE attribute (
    id_attribute SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    type VARCHAR(50),
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLA 10-12: CATALOG MODULE
-- =====================================================

-- 10. category
CREATE TABLE category (
    id_category SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    code VARCHAR(10) NOT NULL UNIQUE,
    description TEXT,
    status product_status NOT NULL DEFAULT 'Active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_category_code ON category(code);

-- 11. subcategory
CREATE TABLE subcategory (
    id_subcategory SERIAL PRIMARY KEY,
    id_category INT NOT NULL REFERENCES category(id_category) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    code VARCHAR(10) NOT NULL,
    description TEXT,
    status product_status NOT NULL DEFAULT 'Active',
    UNIQUE(id_category, code)
);
CREATE INDEX idx_subcategory_category ON subcategory(id_category);

-- 12. brand
CREATE TABLE brand (
    id_brand SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    code VARCHAR(20) NOT NULL UNIQUE,
    description TEXT,
    website VARCHAR(255),
    country VARCHAR(100),
    status product_status NOT NULL DEFAULT 'Active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_brand_code ON brand(code);

-- =====================================================
-- TABLA 13-24: PRODUCT MODULE
-- =====================================================

-- 13. product
CREATE TABLE product (
    id_product SERIAL PRIMARY KEY,
    id_category INT NOT NULL REFERENCES category(id_category) ON DELETE RESTRICT,
    id_subcategory INT REFERENCES subcategory(id_subcategory) ON DELETE SET NULL,
    id_brand INT NOT NULL REFERENCES brand(id_brand) ON DELETE RESTRICT,
    name VARCHAR(255) NOT NULL,
    code_sku VARCHAR(50) NOT NULL UNIQUE,
    description_short VARCHAR(500),
    description_long TEXT,
    price_base DECIMAL(10,2) NOT NULL,
    cost DECIMAL(10,2),
    weight_kg DECIMAL(8,3),
    dimensions_cm VARCHAR(50),
    status product_status NOT NULL DEFAULT 'Active',
    featured BOOLEAN DEFAULT FALSE,
    average_rating DECIMAL(3,2),
    total_reviews INT DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_product_sku ON product(code_sku);
CREATE INDEX idx_product_category ON product(id_category);
CREATE INDEX idx_product_brand ON product(id_brand);
CREATE INDEX idx_product_status ON product(status);

-- 14. product_variant
CREATE TABLE product_variant (
    id_variant SERIAL PRIMARY KEY,
    id_product INT NOT NULL REFERENCES product(id_product) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    value VARCHAR(100),
    code_sku_variant VARCHAR(50) UNIQUE,
    price_additional DECIMAL(10,2) DEFAULT 0,
    weight_variant_kg DECIMAL(8,3),
    status product_status NOT NULL DEFAULT 'Active',
    UNIQUE(id_product, name, value)
);
CREATE INDEX idx_variant_product ON product_variant(id_product);

-- 15. product_specification
CREATE TABLE product_specification (
    id_specification SERIAL PRIMARY KEY,
    id_product INT NOT NULL REFERENCES product(id_product) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    value VARCHAR(255) NOT NULL,
    data_type VARCHAR(50),
    unit VARCHAR(50),
    UNIQUE(id_product, name)
);
CREATE INDEX idx_specification_product ON product_specification(id_product);

-- 16. attribute_value (NUEVA)
CREATE TABLE attribute_value (
    id_value SERIAL PRIMARY KEY,
    id_attribute INT NOT NULL REFERENCES attribute(id_attribute) ON DELETE CASCADE,
    value VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(id_attribute, value)
);
CREATE INDEX idx_attribute_value_attribute ON attribute_value(id_attribute);

-- 17. product_attribute (NUEVA)
CREATE TABLE product_attribute (
    id_product_attribute SERIAL PRIMARY KEY,
    id_product INT NOT NULL REFERENCES product(id_product) ON DELETE CASCADE,
    id_attribute INT NOT NULL REFERENCES attribute(id_attribute) ON DELETE RESTRICT,
    id_value INT NOT NULL REFERENCES attribute_value(id_value) ON DELETE RESTRICT,
    UNIQUE(id_product, id_attribute, id_value)
);
CREATE INDEX idx_product_attribute_product ON product_attribute(id_product);
CREATE INDEX idx_product_attribute_attribute ON product_attribute(id_attribute);

-- 18. product_price
CREATE TABLE product_price (
    id_price SERIAL PRIMARY KEY,
    id_product INT NOT NULL REFERENCES product(id_product) ON DELETE CASCADE,
    current_price DECIMAL(10,2) NOT NULL,
    previous_price DECIMAL(10,2),
    start_date DATE NOT NULL,
    end_date DATE,
    reason VARCHAR(255),
    status product_status NOT NULL DEFAULT 'Active'
);
CREATE INDEX idx_price_product ON product_price(id_product);

-- 19. discount
CREATE TABLE discount (
    id_discount SERIAL PRIMARY KEY,
    id_product INT REFERENCES product(id_product) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    type discount_type NOT NULL,
    value DECIMAL(10,2) NOT NULL,
    max_discount DECIMAL(12,2),
    min_purchase_value DECIMAL(10,2),
    max_uses INT,
    current_uses INT DEFAULT 0,
    status product_status NOT NULL DEFAULT 'Active',
    applies_to VARCHAR(255),
    excludes_products VARCHAR(255),
    created_by VARCHAR(150),
    created_at DATE DEFAULT CURRENT_DATE,
    start_date DATE NOT NULL,
    expiration_date DATE NOT NULL,
    single_use_per_customer BOOLEAN DEFAULT FALSE
);
CREATE INDEX idx_discount_product ON discount(id_product);

-- 20. product_image
CREATE TABLE product_image (
    id_image SERIAL PRIMARY KEY,
    id_product INT NOT NULL REFERENCES product(id_product) ON DELETE CASCADE,
    url VARCHAR(500) NOT NULL,
    alt_text VARCHAR(255),
    order_position INT DEFAULT 0,
    is_primary BOOLEAN DEFAULT FALSE,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_image_product ON product_image(id_product);

-- 21. product_document
CREATE TABLE product_document (
    id_document SERIAL PRIMARY KEY,
    id_product INT NOT NULL REFERENCES product(id_product) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50),
    url VARCHAR(500) NOT NULL,
    size_kb INT,
    language VARCHAR(10),
    publication_date DATE,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_document_product ON product_document(id_product);

-- =====================================================
-- TABLA 22-28: INVENTORY MODULE
-- =====================================================

-- 22. warehouse
CREATE TABLE warehouse (
    id_warehouse SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    code VARCHAR(10) NOT NULL UNIQUE,
    city VARCHAR(100) NOT NULL,
    address VARCHAR(255),
    capacity_tons DECIMAL(10,2),
    manager VARCHAR(150),
    email VARCHAR(100),
    phone VARCHAR(20),
    status product_status NOT NULL DEFAULT 'Active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_warehouse_code ON warehouse(code);

-- 23. stock
CREATE TABLE stock (
    id_stock SERIAL PRIMARY KEY,
    id_product INT NOT NULL REFERENCES product(id_product) ON DELETE CASCADE,
    id_warehouse INT NOT NULL REFERENCES warehouse(id_warehouse) ON DELETE CASCADE,
    available_quantity INT NOT NULL DEFAULT 0,
    reserved_quantity INT DEFAULT 0,
    damaged_quantity INT DEFAULT 0,
    total_quantity INT GENERATED ALWAYS AS (available_quantity + reserved_quantity) STORED,
    last_count_date DATE,
    UNIQUE(id_product, id_warehouse)
);
CREATE INDEX idx_stock_warehouse ON stock(id_warehouse);
CREATE INDEX idx_stock_product ON stock(id_product);

-- 24. inventory_movement
CREATE TABLE inventory_movement (
    id_movement SERIAL PRIMARY KEY,
    id_product INT NOT NULL REFERENCES product(id_product) ON DELETE RESTRICT,
    id_warehouse INT NOT NULL REFERENCES warehouse(id_warehouse) ON DELETE RESTRICT,
    movement_type movement_type NOT NULL,
    quantity INT NOT NULL,
    quantity_before INT,
    quantity_after INT,
    reason TEXT,
    document_reference VARCHAR(100),
    responsible_user VARCHAR(150),
    movement_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_movement_product ON inventory_movement(id_product);
CREATE INDEX idx_movement_warehouse ON inventory_movement(id_warehouse);

-- 25. supplier
CREATE TABLE supplier (
    id_supplier SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL UNIQUE,
    nit VARCHAR(20) UNIQUE,
    contact_person VARCHAR(150),
    email VARCHAR(100),
    phone VARCHAR(20),
    mobile VARCHAR(20),
    city VARCHAR(100),
    country VARCHAR(100),
    address TEXT,
    payment_terms VARCHAR(255),
    delivery_time_days INT,
    min_order_quantity INT,
    status product_status NOT NULL DEFAULT 'Active',
    average_rating DECIMAL(3,2),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_supplier_nit ON supplier(nit);

-- 26. purchase_order
CREATE TABLE purchase_order (
    id_purchase_order SERIAL PRIMARY KEY,
    id_supplier INT NOT NULL REFERENCES supplier(id_supplier) ON DELETE RESTRICT,
    po_number VARCHAR(50) NOT NULL UNIQUE,
    order_date DATE NOT NULL,
    estimated_delivery_date DATE,
    actual_delivery_date DATE,
    quantity_items INT,
    total_value DECIMAL(12,2),
    status product_status NOT NULL DEFAULT 'Active',
    observations TEXT,
    responsible_user VARCHAR(150)
);
CREATE INDEX idx_purchase_order_supplier ON purchase_order(id_supplier);

-- 27. receipt
CREATE TABLE receipt (
    id_receipt SERIAL PRIMARY KEY,
    id_purchase_order INT NOT NULL REFERENCES purchase_order(id_purchase_order) ON DELETE RESTRICT,
    id_warehouse INT NOT NULL REFERENCES warehouse(id_warehouse) ON DELETE RESTRICT,
    receipt_number VARCHAR(50) NOT NULL UNIQUE,
    receipt_date DATE NOT NULL,
    quantity_received INT,
    quantity_inspected INT,
    quantity_accepted INT,
    quantity_rejected INT,
    observations TEXT,
    receiving_user VARCHAR(150),
    status receipt_status NOT NULL DEFAULT 'Pending'
);
CREATE INDEX idx_receipt_warehouse ON receipt(id_warehouse);

-- 28. adjustment (NUEVA - Para ajustes de inventario)
CREATE TABLE adjustment (
    id_adjustment SERIAL PRIMARY KEY,
    id_product INT NOT NULL REFERENCES product(id_product) ON DELETE CASCADE,
    id_warehouse INT NOT NULL REFERENCES warehouse(id_warehouse) ON DELETE CASCADE,
    quantity_before INT NOT NULL,
    quantity_adjustment INT NOT NULL,
    quantity_after INT NOT NULL,
    reason VARCHAR(255),
    document_reference VARCHAR(100),
    user_authorized VARCHAR(150),
    adjustment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved BOOLEAN DEFAULT FALSE,
    user_approver VARCHAR(150)
);
CREATE INDEX idx_adjustment_product ON adjustment(id_product);
CREATE INDEX idx_adjustment_warehouse ON adjustment(id_warehouse);

-- =====================================================
-- TABLA 29-32: CLIENT MODULE
-- =====================================================

-- 29. client
CREATE TABLE client (
    id_client SERIAL PRIMARY KEY,
    id_user INT REFERENCES user(id_user) ON DELETE SET NULL,
    document_type document_type NOT NULL,
    document_number VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    mobile VARCHAR(20),
    gender VARCHAR(1),
    birth_date DATE,
    company VARCHAR(200),
    client_type client_type NOT NULL DEFAULT 'Natural',
    status user_status NOT NULL DEFAULT 'Active',
    registration_date DATE DEFAULT CURRENT_DATE,
    total_purchases INT DEFAULT 0,
    total_purchase_value DECIMAL(12,2) DEFAULT 0,
    contact_preference VARCHAR(50),
    accepts_promotions BOOLEAN DEFAULT TRUE,
    last_purchase_date DATE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_client_document ON client(document_number);
CREATE INDEX idx_client_email ON client(id_user);

-- 30. client_address
CREATE TABLE client_address (
    id_address SERIAL PRIMARY KEY,
    id_client INT NOT NULL REFERENCES client(id_client) ON DELETE CASCADE,
    type address_type NOT NULL,
    address_name VARCHAR(100),
    street_address VARCHAR(255) NOT NULL,
    apartment VARCHAR(50),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'Colombia',
    phone VARCHAR(20),
    additional_reference TEXT,
    is_primary BOOLEAN DEFAULT FALSE,
    status user_status NOT NULL DEFAULT 'Active',
    latitude DECIMAL(10,8),
    longitude DECIMAL(10,8)
);
CREATE INDEX idx_address_client ON client_address(id_client);

-- 31. client_phone
CREATE TABLE client_phone (
    id_phone SERIAL PRIMARY KEY,
    id_client INT NOT NULL REFERENCES client(id_client) ON DELETE CASCADE,
    phone_number VARCHAR(20) NOT NULL,
    type phone_type NOT NULL,
    operator VARCHAR(50),
    is_primary BOOLEAN DEFAULT FALSE,
    verified BOOLEAN DEFAULT FALSE,
    verification_date DATE
);
CREATE INDEX idx_phone_client ON client_phone(id_client);

-- 32. client_preference
CREATE TABLE client_preference (
    id_preference SERIAL PRIMARY KEY,
    id_client INT NOT NULL REFERENCES client(id_client) ON DELETE CASCADE,
    receives_newsletter BOOLEAN DEFAULT TRUE,
    receives_sms BOOLEAN DEFAULT FALSE,
    receives_email BOOLEAN DEFAULT TRUE,
    receives_push_notification BOOLEAN DEFAULT TRUE,
    contact_frequency VARCHAR(50),
    interest_categories VARCHAR(500),
    preferred_payment_method VARCHAR(100),
    contact_schedule VARCHAR(100),
    notes TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLA 33-39: ORDER MODULE
-- =====================================================

-- 33. cart
CREATE TABLE cart (
    id_cart SERIAL PRIMARY KEY,
    id_client INT NOT NULL REFERENCES client(id_client) ON DELETE CASCADE,
    subtotal DECIMAL(12,2) DEFAULT 0,
    discounts DECIMAL(12,2) DEFAULT 0,
    total DECIMAL(12,2) DEFAULT 0,
    items_quantity INT DEFAULT 0,
    status cart_status NOT NULL DEFAULT 'Active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    abandoned_at TIMESTAMP,
    UNIQUE(id_client)
);
CREATE INDEX idx_cart_client ON cart(id_client);

-- 34. cart_item
CREATE TABLE cart_item (
    id_cart_item SERIAL PRIMARY KEY,
    id_cart INT NOT NULL REFERENCES cart(id_cart) ON DELETE CASCADE,
    id_product INT NOT NULL REFERENCES product(id_product) ON DELETE RESTRICT,
    id_variant INT REFERENCES product_variant(id_variant) ON DELETE SET NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(id_cart, id_product, id_variant)
);
CREATE INDEX idx_cart_item_product ON cart_item(id_product);

-- 35. order_table
CREATE TABLE order_table (
    id_order SERIAL PRIMARY KEY,
    id_client INT NOT NULL REFERENCES client(id_client) ON DELETE RESTRICT,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    items_quantity INT NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    discounts DECIMAL(12,2) DEFAULT 0,
    taxes DECIMAL(12,2),
    shipping_cost DECIMAL(10,2),
    total DECIMAL(12,2) NOT NULL,
    status order_status NOT NULL DEFAULT 'Pending',
    payment_method_id INT,
    observations TEXT,
    ip_client VARCHAR(45),
    device VARCHAR(50),
    confirmed_at TIMESTAMP,
    estimated_delivery_date DATE,
    actual_delivery_date DATE
);
CREATE INDEX idx_order_client ON order_table(id_client);
CREATE INDEX idx_order_number ON order_table(order_number);
CREATE INDEX idx_order_status ON order_table(status);

-- 36. order_detail
CREATE TABLE order_detail (
    id_order_detail SERIAL PRIMARY KEY,
    id_order INT NOT NULL REFERENCES order_table(id_order) ON DELETE CASCADE,
    id_product INT NOT NULL REFERENCES product(id_product) ON DELETE RESTRICT,
    id_variant INT REFERENCES product_variant(id_variant) ON DELETE SET NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    line_discount DECIMAL(10,2) DEFAULT 0,
    line_subtotal DECIMAL(12,2) NOT NULL,
    status order_detail_status NOT NULL DEFAULT 'Pending'
);
CREATE INDEX idx_order_detail_order ON order_detail(id_order);
CREATE INDEX idx_order_detail_product ON order_detail(id_product);

-- 37. order_status_history
CREATE TABLE order_status_history (
    id_status_history SERIAL PRIMARY KEY,
    id_order INT NOT NULL REFERENCES order_table(id_order) ON DELETE CASCADE,
    status order_status NOT NULL,
    description TEXT,
    responsible_user VARCHAR(150),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_status_history_order ON order_status_history(id_order);

-- 38. historial_navegacion (NUEVA - Para rastreo de navegación)
CREATE TABLE historial_navegacion (
    id_historial SERIAL PRIMARY KEY,
    id_client INT REFERENCES client(id_client) ON DELETE CASCADE,
    id_product INT REFERENCES product(id_product) ON DELETE CASCADE,
    tipo_evento VARCHAR(100) NOT NULL,
    duracion_segundos INT,
    dispositivo VARCHAR(50),
    navegador VARCHAR(100),
    ip_cliente VARCHAR(45),
    fecha_evento TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_historial_client ON historial_navegacion(id_client);

-- 39. lista_deseos (NUEVA - Para lista de favoritos)
CREATE TABLE lista_deseos (
    id_lista_deseos SERIAL PRIMARY KEY,
    id_client INT NOT NULL REFERENCES client(id_client) ON DELETE CASCADE,
    id_product INT NOT NULL REFERENCES product(id_product) ON DELETE CASCADE,
    nombre_lista VARCHAR(100) DEFAULT 'Mi Lista',
    prioridad INT DEFAULT 0,
    notificar_cambio_precio BOOLEAN DEFAULT FALSE,
    precio_alerta DECIMAL(10,2),
    fecha_agregado TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(id_client, id_product)
);
CREATE INDEX idx_lista_deseos_client ON lista_deseos(id_client);

-- =====================================================
-- TABLA 40-43: SHIPPING MODULE
-- =====================================================

-- 40. shipping
CREATE TABLE shipping (
    id_shipping SERIAL PRIMARY KEY,
    id_order INT NOT NULL REFERENCES order_table(id_order) ON DELETE CASCADE,
    id_address INT NOT NULL REFERENCES client_address(id_address) ON DELETE RESTRICT,
    carrier VARCHAR(150),
    tracking_number VARCHAR(100) UNIQUE,
    dispatch_date DATE,
    estimated_delivery_date DATE,
    actual_delivery_date DATE,
    shipping_cost DECIMAL(10,2),
    status shipping_status NOT NULL DEFAULT 'Pending',
    customer_signature VARCHAR(255),
    observations TEXT
);
CREATE INDEX idx_shipping_order ON shipping(id_order);

-- 41. shipping_tracking
CREATE TABLE shipping_tracking (
    id_tracking SERIAL PRIMARY KEY,
    id_shipping INT NOT NULL REFERENCES shipping(id_shipping) ON DELETE CASCADE,
    city VARCHAR(100),
    tracking_status VARCHAR(100),
    description TEXT,
    tracked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    latitude DECIMAL(10,8),
    longitude DECIMAL(10,8)
);
CREATE INDEX idx_tracking_shipping ON shipping_tracking(id_shipping);

-- 42. return_order
CREATE TABLE return_order (
    id_return SERIAL PRIMARY KEY,
    id_order INT NOT NULL REFERENCES order_table(id_order) ON DELETE CASCADE,
    return_number VARCHAR(50) NOT NULL UNIQUE,
    request_date DATE NOT NULL,
    reason VARCHAR(255) NOT NULL,
    problem_description TEXT,
    status return_status NOT NULL DEFAULT 'Requested',
    approval_date DATE,
    approver VARCHAR(150),
    observations TEXT,
    received_date DATE,
    returned_condition VARCHAR(100)
);
CREATE INDEX idx_return_order ON return_order(id_order);

-- 43. return_detail
CREATE TABLE return_detail (
    id_return_detail SERIAL PRIMARY KEY,
    id_return INT NOT NULL REFERENCES return_order(id_return) ON DELETE CASCADE,
    id_product INT NOT NULL REFERENCES product(id_product) ON DELETE RESTRICT,
    returned_quantity INT NOT NULL,
    condition return_condition NOT NULL,
    refund_value DECIMAL(10,2) NOT NULL,
    rejection_reason VARCHAR(255),
    accepted BOOLEAN DEFAULT FALSE
);
CREATE INDEX idx_return_detail_return ON return_detail(id_return);

-- =====================================================
-- TABLA 44-46: PAYMENT MODULE
-- =====================================================

-- 44. payment_method
CREATE TABLE payment_method (
    id_payment_method SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    type payment_method_type NOT NULL,
    description TEXT,
    commission_percentage DECIMAL(5,2),
    commission_fixed DECIMAL(10,2),
    status product_status NOT NULL DEFAULT 'Active',
    requires_verification BOOLEAN DEFAULT FALSE,
    processing_days INT
);

-- 45. payment_transaction
CREATE TABLE payment_transaction (
    id_transaction SERIAL PRIMARY KEY,
    id_order INT NOT NULL REFERENCES order_table(id_order) ON DELETE CASCADE,
    id_payment_method INT NOT NULL REFERENCES payment_method(id_payment_method) ON DELETE RESTRICT,
    transaction_number VARCHAR(100) NOT NULL UNIQUE,
    transaction_value DECIMAL(12,2) NOT NULL,
    commission DECIMAL(10,2) DEFAULT 0,
    net_value DECIMAL(12,2),
    status payment_status NOT NULL DEFAULT 'Pending',
    processor_bank VARCHAR(150),
    response_code VARCHAR(50),
    response_description TEXT,
    external_reference VARCHAR(100),
    origin_ip VARCHAR(45),
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processing_date TIMESTAMP,
    approval_date TIMESTAMP,
    transaction_token VARCHAR(255),
    last_4_digits VARCHAR(4)
);
CREATE INDEX idx_transaction_order ON payment_transaction(id_order);
CREATE INDEX idx_transaction_status ON payment_transaction(status);

-- 46. refund
CREATE TABLE refund (
    id_refund SERIAL PRIMARY KEY,
    id_return INT NOT NULL REFERENCES return_order(id_return) ON DELETE CASCADE,
    id_order INT NOT NULL REFERENCES order_table(id_order) ON DELETE RESTRICT,
    refund_number VARCHAR(50) NOT NULL UNIQUE,
    refund_value DECIMAL(12,2) NOT NULL,
    refund_type VARCHAR(20) NOT NULL,
    status payment_status NOT NULL DEFAULT 'Pending',
    refund_method VARCHAR(100),
    request_date DATE NOT NULL,
    processing_date DATE,
    completed_date DATE,
    bank_reference VARCHAR(100),
    observations TEXT,
    authorized_by VARCHAR(150)
);
CREATE INDEX idx_refund_return ON refund(id_return);

-- =====================================================
-- TABLA 47-51: PRODUCT RELATIONS MODULE
-- =====================================================

-- 47. product_related
CREATE TABLE product_related (
    id_related SERIAL PRIMARY KEY,
    id_main_product INT NOT NULL REFERENCES product(id_product) ON DELETE CASCADE,
    id_related_product INT NOT NULL REFERENCES product(id_product) ON DELETE CASCADE,
    relation_type VARCHAR(100),
    order_position INT DEFAULT 0,
    UNIQUE(id_main_product, id_related_product)
);
CREATE INDEX idx_related_main ON product_related(id_main_product);

-- 48. product_bundle
CREATE TABLE product_bundle (
    id_bundle SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL UNIQUE,
    description TEXT,
    bundle_price DECIMAL(10,2) NOT NULL,
    total_discount DECIMAL(10,2),
    items_quantity INT,
    status product_status NOT NULL DEFAULT 'Active',
    bundle_image VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 49. product_compatibility
CREATE TABLE product_compatibility (
    id_compatibility SERIAL PRIMARY KEY,
    id_product_a INT NOT NULL REFERENCES product(id_product) ON DELETE CASCADE,
    id_product_b INT NOT NULL REFERENCES product(id_product) ON DELETE CASCADE,
    compatibility_type VARCHAR(100),
    compatibility_percentage INT,
    technical_notes TEXT,
    UNIQUE(id_product_a, id_product_b)
);
CREATE INDEX idx_compatibility_product_a ON product_compatibility(id_product_a);

-- 50. product_review
CREATE TABLE product_review (
    id_review SERIAL PRIMARY KEY,
    id_product INT NOT NULL REFERENCES product(id_product) ON DELETE CASCADE,
    id_client INT NOT NULL REFERENCES client(id_client) ON DELETE RESTRICT,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(200),
    comment TEXT,
    verified_purchase BOOLEAN DEFAULT FALSE,
    order_number VARCHAR(50),
    helpful_yes INT DEFAULT 0,
    helpful_no INT DEFAULT 0,
    seller_response TEXT,
    status product_status NOT NULL DEFAULT 'Active',
    moderator VARCHAR(150),
    approval_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_review_product ON product_review(id_product);
CREATE INDEX idx_review_client ON product_review(id_client);

-- 51. product_sustituto (NUEVA - Para productos sustitutos)
CREATE TABLE product_sustituto (
    id_sustituto SERIAL PRIMARY KEY,
    id_product_original INT NOT NULL REFERENCES product(id_product) ON DELETE CASCADE,
    id_product_sustituto INT NOT NULL REFERENCES product(id_product) ON DELETE CASCADE,
    razon_sustitucion VARCHAR(255),
    diferencia_precio DECIMAL(10,2),
    ventajas TEXT,
    desventajas TEXT,
    UNIQUE(id_product_original, id_product_sustituto)
);
CREATE INDEX idx_sustituto_original ON product_sustituto(id_product_original);

-- =====================================================
-- TABLA 52-54: COUPON MODULE
-- =====================================================

-- 52. coupon
CREATE TABLE coupon (
    id_coupon SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    type discount_type NOT NULL,
    value DECIMAL(10,2) NOT NULL,
    max_discount DECIMAL(12,2),
    min_purchase_value DECIMAL(10,2),
    max_total_uses INT,
    current_uses INT DEFAULT 0,
    status product_status NOT NULL DEFAULT 'Active',
    applies_to VARCHAR(255),
    excludes_products VARCHAR(255),
    created_by VARCHAR(150),
    created_at DATE DEFAULT CURRENT_DATE,
    start_date DATE NOT NULL,
    expiration_date DATE NOT NULL,
    single_use_per_client BOOLEAN DEFAULT FALSE
);
CREATE INDEX idx_coupon_code ON coupon(code);
CREATE INDEX idx_coupon_status ON coupon(status);

-- 53. coupon_usage
CREATE TABLE coupon_usage (
    id_usage SERIAL PRIMARY KEY,
    id_coupon INT NOT NULL REFERENCES coupon(id_coupon) ON DELETE CASCADE,
    id_client INT NOT NULL REFERENCES client(id_client) ON DELETE RESTRICT,
    id_order INT NOT NULL REFERENCES order_table(id_order) ON DELETE RESTRICT,
    discount_applied DECIMAL(12,2),
    used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_usage_coupon ON coupon_usage(id_coupon);
CREATE INDEX idx_usage_client ON coupon_usage(id_client);

-- 54. historial_cupones (NUEVA - Para historial de cupones)
CREATE TABLE historial_cupones (
    id_historial SERIAL PRIMARY KEY,
    id_coupon INT NOT NULL REFERENCES coupon(id_coupon) ON DELETE CASCADE,
    id_client INT REFERENCES client(id_client) ON DELETE SET NULL,
    accion VARCHAR(100),
    descripcion TEXT,
    fecha_accion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_historial_cupones_coupon ON historial_cupones(id_coupon);

-- =====================================================
-- TOTAL: 54 TABLAS ✅
-- =====================================================

-- Comentario final
SELECT '54 TABLAS CREADAS EXITOSAMENTE - TechStoreIntelligentSystem' AS resultado;
