
CREATE PROCEDURE public.create_payment_orders(IN jsondetails json)
    LANGUAGE plpgsql
    AS $$
DECLARE
	v_first_shopping_id INT;
    v_supplier_id INT;
	
	v_status VARCHAR;
	v_payment_date DATE; 
    v_shoppings JSON;
	v_payment_order_id INT;
	v_amount_payable DOUBLE PRECISION ;
	
BEGIN
    v_payment_date := (jsonDetails->>'payment_date')::DATE;
	v_status := (jsonDetails->>'status')::VARCHAR;
    v_shoppings := jsonDetails->'shoppings';
	
	-- Extraer el shopping_id del primer producto
    SELECT (json_array_elements(v_shoppings)->>'shopping_id')::INT INTO v_first_shopping_id FROM json_array_elements(v_shoppings) LIMIT 1;
	-- Obtener el supplier_id de la primera compra
    SELECT supplier_customer_id INTO v_supplier_id FROM view_shoppings WHERE id = v_first_shopping_id;
	

    -- Crear la orden de pago
    INSERT INTO payment_orders (payment_date,status,created_at,updated_at) VALUES (v_payment_date,v_status,NOW(), NOW()) RETURNING id INTO v_payment_order_id;

    -- Iterar sobre cada objeto en el arreglo de productos
    FOR v_shoppings IN SELECT * FROM json_array_elements(v_shoppings)
    LOOP
		-- VALIDAR(las compras sean del mismo proveedor,el monto de cada compra sea menor o igual al monto faltante por abonar)
		-- RAISE NOTICE 'Procesando producto: %', (v_shoppings->>'shopping_id')::INT;
		IF NOT EXISTS (SELECT 1 FROM view_shoppings WHERE id = (v_shoppings->>'shopping_id')::INT AND supplier_customer_id=v_supplier_id) THEN
			RAISE EXCEPTION 'La compra % no pertenece al proveedor con id %',(v_shoppings->>'shopping_id')::INT,v_supplier_id;
		END IF;
		
		SELECT COALESCE(amount_payable, 0) INTO v_amount_payable FROM view_shoppings_summary WHERE id = (v_shoppings->>'shopping_id')::INT;
		
		-- Verificar si el amount es menor o igual al saldo por pagar
		IF (v_shoppings->>'amount')::DOUBLE PRECISION > v_amount_payable THEN
			RAISE EXCEPTION 'El monto de la compra % es mayor que el saldo disponible. Monto de la compra: %, Saldo: %',
								(v_shoppings->>'shopping_id')::INT, (v_shoppings->>'amount')::DOUBLE PRECISION, v_amount_payable;
		END IF;
		RAISE NOTICE 'Procesando producto: %', (v_shoppings->>'amount')::INT;
		
		INSERT INTO purchase_orders (shopping_id,amount, payment_order_id,created_at,updated_at) 
			VALUES ((v_shoppings->>'shopping_id')::INT,(v_shoppings->>'amount')::DOUBLE PRECISION, v_payment_order_id,NOW(),NOW());
    END LOOP;
EXCEPTION
    WHEN others THEN RAISE;-- Manejo de errores
END;
$$;