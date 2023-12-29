-- DROP PROCEDURE IF EXISTS create_payment_orders;
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