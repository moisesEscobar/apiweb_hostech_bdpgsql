-- DROP FUNCTION create_payment_order_txns;
CREATE OR REPLACE FUNCTION public.create_payment_order_txns(p_status character varying, p_user_id integer, p_payment_type_id integer, p_payment_order_id integer, p_supplier_customer_id integer)
RETURNS json LANGUAGE plpgsql AS $function$

DECLARE v_new_record_id INT;
DECLARE v_total_amount INT;

BEGIN
    -- Validar payment_type_id
    IF NOT EXISTS (SELECT 1 FROM payment_types WHERE id = p_payment_type_id) THEN
        RAISE EXCEPTION 'payment_type_id % no existe', p_payment_type_id;
    END IF;
    -- Validar payment_order_id
    IF NOT EXISTS (SELECT 1 FROM payment_orders WHERE id = p_payment_order_id) THEN
        RAISE EXCEPTION 'payment_order_id % no existe', p_payment_order_id;
    END IF;
	SELECT COALESCE(total_amount, 0) INTO v_total_amount FROM view_payment_orders WHERE id = p_payment_order_id;
	
    -- Validar supplier_customer_id
    IF NOT EXISTS (SELECT 1 FROM suppliers_customers WHERE id = p_supplier_customer_id) THEN
        RAISE EXCEPTION 'supplier_customer_id % no existe', p_supplier_customer_id;
    END IF;
	
	-- Verificar duplicados
    IF EXISTS (SELECT 1 FROM payment_order_txns where
        payment_type_id = p_payment_type_id 
            AND payment_order_id = p_payment_order_id 
            AND supplier_customer_id = p_supplier_customer_id) THEN
        RAISE EXCEPTION 'Un registro con los mismos payment_type_id, payment_order_id y supplier_customer_id ya existe';
    END IF;

    -- Realizar la inserción en payment_order_txns
    INSERT INTO payment_order_txns (user_id, payment_type_id, payment_order_id, supplier_customer_id, status, amount, created_at, updated_at)
    VALUES (p_user_id, p_payment_type_id, p_payment_order_id, p_supplier_customer_id, p_status, v_total_amount, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) RETURNING id INTO v_new_record_id;

    -- Devolver el registro creado en formato JSON
    RETURN (SELECT json_build_object(
        'id', id, 
        'status', status,
        'user_id', user_id,
        'payment_type_id', payment_type_id,
        'payment_order_id', payment_order_id,
        'supplier_customer_id', supplier_customer_id,
        'amount', amount,
        'created_at', created_at,
        'updated_at', updated_at
    ) FROM payment_order_txns WHERE id = v_new_record_id);

    EXCEPTION WHEN others THEN RAISE;
END;
$function$