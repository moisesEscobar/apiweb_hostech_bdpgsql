CREATE PROCEDURE public.create_product_sale(IN jsondetails json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_customer_id INT;
	v_date_sale DATE;
	v_product_details JSON;
	v_first_product_id INT;
	v_unit_price DECIMAL(10, 2);
	v_product_sale_id INT;
BEGIN
    -- Extraer los datos de objeto
    v_customer_id := (jsonDetails->>'customer_id')::INT;
	v_date_sale := (jsonDetails->>'date_sale')::DATE;
    v_product_details := jsonDetails->'products';
	
	    -- Validar payment_type_id
    IF NOT EXISTS (SELECT 1 FROM view_suppliers WHERE id = v_customer_id AND type_user='customer') THEN
        RAISE EXCEPTION 'El usuario % no existe como cliente', v_customer_id;
    END IF;

    -- Crear la venta y obtener el ID
    INSERT INTO product_sales (supplier_customer_id,date_sale,created_at,updated_at) VALUES (v_customer_id,v_date_sale,NOW(), NOW()) RETURNING id INTO v_product_sale_id;
	
    -- Iterar sobre cada objeto en el arreglo de productos
    FOR v_product_details IN SELECT * FROM json_array_elements(v_product_details)
    LOOP
		-- Verificar si el product_id existe en la tabla 'view_products'
		IF NOT EXISTS (
			SELECT 1 FROM view_products_with_inventory WHERE product_id = (v_product_details->>'product_id')::INT AND quantity_available>=(v_product_details->>'quantity')::INT
		) THEN
			RAISE EXCEPTION 'El producto % no existe o la cantidad disponible no es suficiente.',(v_product_details->>'product_id')::INT;
		END IF;
		
		SELECT COALESCE(price, 0) INTO v_unit_price FROM view_products WHERE id = (v_product_details->>'product_id')::INT;

		-- Insertar en la tabla 'inventories'
    	INSERT INTO product_sale_details(product_sale_id,product_id,quantity,unit_price,created_at,updated_at) 
			VALUES (
				v_product_sale_id,(v_product_details->>'product_id')::INT, (v_product_details->>'quantity')::INT, v_unit_price,NOW(), NOW()
			);
		-- RAISE NOTICE 'INVENTARIO: %', v_inventory_id;
    END LOOP;
EXCEPTION
    WHEN others THEN RAISE;-- Manejo de errores
END;
$$;
