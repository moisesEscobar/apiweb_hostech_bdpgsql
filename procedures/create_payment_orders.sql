-- DROP PROCEDURE create_payment_orders;
CREATE OR REPLACE PROCEDURE public.create_payment_orders(IN jsondetails json)
LANGUAGE plpgsql AS $procedure$
DECLARE
	v_first_shopping_id INT;
    v_supplier_id INT;
	v_user_id INT;
	v_account_id INT;
	v_status VARCHAR;
	v_payment_date DATE; 
    v_shoppings JSON;
	v_payment_order_id INT;
	v_amount_payable DOUBLE PRECISION ;
	v_supplier_name VARCHAR;
	v_modified_shoppings  JSONB[] := '{}'; 

BEGIN
	v_user_id:= (jsonDetails->>'user_id')::INT;
	v_account_id := (jsonDetails->>'account_id')::INT;
    v_payment_date := (jsonDetails->>'payment_date')::DATE;
	v_status := (jsonDetails->>'status')::VARCHAR;
    v_shoppings := jsonDetails->'shoppings';
	
	-- Validaciones
	IF NOT EXISTS (SELECT 1 FROM accounts WHERE id = v_account_id AND deleted_at IS NULL) THEN
        RAISE EXCEPTION 'La cuenta proporcionada no existe ';
    END IF;
	
	-- Extraer el shopping_id del primer producto
    SELECT (json_array_elements(v_shoppings)->>'shopping_id')::INT INTO v_first_shopping_id FROM json_array_elements(v_shoppings) LIMIT 1;
	-- Obtener el supplier_id de la primera compra
    SELECT supplier_customer_id INTO v_supplier_id FROM view_shoppings WHERE id = v_first_shopping_id;
	SELECT name INTO v_supplier_name FROM view_suppliers WHERE id = v_supplier_id;

    -- Crear la orden de pago
    INSERT INTO payment_orders (payment_date,status,created_at,updated_at) VALUES (v_payment_date,v_status,NOW(), NOW()) RETURNING id INTO v_payment_order_id;

    -- Iterar sobre cada objeto en el arreglo de productos
    FOR v_shoppings IN SELECT * FROM json_array_elements(v_shoppings) LOOP
		-- VALIDAR(las compras sean del mismo proveedor,el monto de cada compra sea menor o igual al monto faltante por abonar)
		IF NOT EXISTS (SELECT 1 FROM view_shoppings WHERE id = (v_shoppings->>'shopping_id')::INT AND supplier_customer_id=v_supplier_id) THEN
			RAISE EXCEPTION 'La compra % no pertenece al proveedor con id %',(v_shoppings->>'shopping_id')::INT,v_supplier_id;
		END IF;

		-- Obtener y Verificar si el amount es menor o igual al saldo por pagar
		SELECT COALESCE(amount_payable, 0) INTO v_amount_payable FROM view_shoppings_summary WHERE id = (v_shoppings->>'shopping_id')::INT;
		IF (v_shoppings->>'amount')::DOUBLE PRECISION > v_amount_payable THEN
			RAISE EXCEPTION 'El monto de la compra % es mayor que el saldo disponible. Monto de la compra: $ % MXN, Saldo: $ % MXN',
				(v_shoppings->>'shopping_id')::INT, (v_shoppings->>'amount')::DOUBLE PRECISION, v_amount_payable;
		END IF;
		-- Insertar ordenes de pago
		INSERT INTO purchase_orders (shopping_id,amount, payment_order_id,created_at,updated_at) 
			VALUES ((v_shoppings->>'shopping_id')::INT,(v_shoppings->>'amount')::DOUBLE PRECISION, v_payment_order_id,NOW(),NOW());
		v_modified_shoppings := array_append(v_modified_shoppings, v_shoppings::jsonb);
	END LOOP;
	-- Crear el log de lo realizado
	CALL create_log(
		v_user_id, 'create'::VARCHAR, 'payment_order_purchase'::VARCHAR,null, 
		jsonb_build_object(
			'payment_date', v_payment_date,
			'supplier_id', v_supplier_id,
			'supplier_name', v_supplier_name,
			'status', v_status,
			'shoppings', v_modified_shoppings
		)
	);
	-- Registrar una entrada 
	CALL create_expenses(v_user_id,v_payment_order_id,v_account_id,null);
	
EXCEPTION WHEN others THEN RAISE;-- Manejo de errores
END;
$procedure$
