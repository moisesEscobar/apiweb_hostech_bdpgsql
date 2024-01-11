DROP PROCEDURE create_order_receive_sales;
CREATE OR REPLACE PROCEDURE public.create_order_receive_sales(IN jsondetails json)
LANGUAGE plpgsql AS $procedure$

DECLARE
	v_user_id INT;
	v_account_id INT;
    v_customer_id INT;
	v_order_receive_id INT;
	v_date_order DATE; 
    v_sales JSON;
	v_amount_payable DOUBLE PRECISION ;
	v_customer_name VARCHAR;
	v_modified_sales JSONB[] := '{}'; 
	
BEGIN
	v_account_id := (jsonDetails->>'account_id')::INT;
	v_user_id := (jsonDetails->>'user_id')::INT;
	v_customer_id := (jsonDetails->>'customer_id')::INT;
    v_date_order := (jsonDetails->>'date_order')::DATE;
    v_sales := jsonDetails->'sales';
	
	-- Validaciones
	IF NOT EXISTS (SELECT 1 FROM accounts WHERE id = v_account_id AND deleted_at IS NULL) THEN
        RAISE EXCEPTION 'La cuenta proporcionada no existe ';
    END IF;
	IF NOT EXISTS (SELECT 1 FROM view_suppliers WHERE id = v_customer_id ) THEN
        RAISE EXCEPTION 'El cliente % no existe', v_customer_id;
    END IF;
	
	-- Extraer el customer_id de la venta a partir del id de la primera venta
	SELECT name INTO v_customer_name FROM view_suppliers where id=v_customer_id;
    -- Crear la orden de cobro
    INSERT INTO order_receive(supplier_customer_id,date_order,created_at,updated_at) 
		VALUES (v_customer_id,v_date_order,NOW(), NOW()) RETURNING id INTO v_order_receive_id;

    -- Iterar sobre cada objeto en el arreglo de ventas
    FOR v_sales IN SELECT * FROM json_array_elements(v_sales) LOOP
		-- VALIDAR(las compras sean del mismo cliente,el monto de cada compra sea menor o igual al monto faltante por abonar)
		IF NOT EXISTS (SELECT 1 FROM view_product_sales WHERE id = (v_sales->>'product_sale_id')::INT AND supplier_customer_id=v_customer_id) THEN
			RAISE EXCEPTION 'La venta  % no existe o no pertenece al cliente con id %',(v_sales->>'product_sale_id')::INT,v_customer_id;
		END IF;

		-- Obtener y verificar si el amount es menor o igual al saldo por pagar
		SELECT COALESCE(amount_payable, 0) INTO v_amount_payable FROM view_products_sales_summary WHERE id = (v_sales->>'product_sale_id')::INT;
		IF (v_sales->>'amount')::DOUBLE PRECISION > v_amount_payable THEN
			RAISE EXCEPTION 'El monto de la compra % es mayor que el saldo disponible. Monto de la venta: $ % MXN, Saldo: $ % MXN',
				(v_sales->>'product_sale_id')::INT, (v_sales->>'amount')::DOUBLE PRECISION, v_amount_payable;
		END IF;
		
		INSERT INTO order_receive_sales (product_sale_id,amount,order_receive_id,created_at,updated_at) 
			VALUES ((v_sales->>'product_sale_id')::INT,(v_sales->>'amount')::DOUBLE PRECISION, v_order_receive_id,NOW(),NOW());
		v_modified_sales := array_append(v_modified_sales, v_sales::jsonb);
	END LOOP;
	-- Crear el log de lo realizado
	CALL create_log(
		v_user_id, 'create'::VARCHAR, 'order_receive'::VARCHAR, null, 
		jsonb_build_object(
			'customer_id', v_customer_id,
			'date_order', v_date_order,
			'customer_name',v_customer_name,
			'sales',v_modified_sales
		)
	);
	CALL create_incomes(v_user_id::INT,v_order_receive_id,v_account_id,null::INT);
	EXCEPTION WHEN others THEN RAISE;
END;
$procedure$
