
DROP PROCEDURE IF EXISTS create_log;
CREATE OR REPLACE PROCEDURE public.create_log(IN p_user_id integer, IN p_action character varying, IN p_catalog character varying, IN p_detail_last jsonb, IN p_detail_new jsonb)
LANGUAGE plpgsql
AS $procedure$
BEGIN
	INSERT INTO logs (user_id, action, catalog, detail_last, detail_new, created_at,updated_at)
	VALUES (p_user_id, p_action, p_catalog, p_detail_last, p_detail_new, NOW(),NOW());
EXCEPTION
    WHEN others THEN RAISE;-- En caso de error, se revierte la transacción automáticamente
END;$procedure$
;



DROP PROCEDURE IF EXISTS create_payment_orders;
CREATE OR REPLACE PROCEDURE public.create_payment_orders(IN p_shopping_id integer, IN p_payment_date date, IN p_status character varying)
LANGUAGE plpgsql
AS $procedure$
DECLARE
    v_exists_shopping BOOLEAN;
    v_payment_order_id INT;
BEGIN
    -- Verificar si el shopping_id existe
    SELECT EXISTS(SELECT 1 FROM shoppings WHERE id = p_shopping_id) INTO v_exists_shopping;
    IF NOT v_exists_shopping THEN
        RAISE EXCEPTION 'El shopping_id % no existe', p_shopping_id;
    END IF;
    -- Insertar en la tabla 'payment_orders'
    INSERT INTO payment_orders (payment_date, status,created_at,updated_at) VALUES (p_payment_date, p_status,NOW(),NOW()) RETURNING id INTO v_payment_order_id;
    -- Insertar en la tabla 'purchase_orders'
    INSERT INTO purchase_orders (shopping_id, payment_order_id,created_at,updated_at) VALUES (p_shopping_id, v_payment_order_id,NOW(),NOW());
EXCEPTION
    WHEN others THEN RAISE;-- En caso de error, se revierte la transacción automáticamente
END;
$procedure$
;



DROP PROCEDURE IF EXISTS create_shoping_and_inventories;
CREATE OR REPLACE PROCEDURE public.create_shoping_and_inventories(IN p_product_id integer, IN p_quantity integer, IN p_unit_price numeric)
LANGUAGE plpgsql
AS $procedure$
DECLARE
    v_inventory_id INT;
    v_product_count INT;
BEGIN
    -- Verificar si el product_id existe en la tabla 'products'
    SELECT COUNT(*) INTO v_product_count FROM products WHERE id = p_product_id;
    -- Si el product_id no existe, lanzar una excepción
    IF v_product_count = 0 THEN
        RAISE EXCEPTION 'El product_id % no existe en la tabla products', p_product_id;
    END IF;
    -- Insertar en la tabla 'inventories'
    INSERT INTO inventories (product_id, quantity,created_at,updated_at) VALUES (p_product_id, p_quantity, NOW(), NOW()) RETURNING id INTO v_inventory_id;
    -- Insertar en la tabla 'shoppings' usando el 'inventory_id' obtenido
    INSERT INTO shoppings (inventory_id, unit_price,created_at,updated_at) VALUES (v_inventory_id, p_unit_price, NOW(), NOW());
EXCEPTION
    WHEN others THEN RAISE;-- En caso de error, se revierte la transacción automáticamente
END;
$procedure$
;