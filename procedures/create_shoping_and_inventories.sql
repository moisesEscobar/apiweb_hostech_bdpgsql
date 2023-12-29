-- DROP PROCEDURE IF EXISTS create_shoping_and_inventories;
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