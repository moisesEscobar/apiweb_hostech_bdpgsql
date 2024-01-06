CREATE PROCEDURE public.create_shopping_and_inventories(IN jsondetails json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_supplier_id INT;
	v_first_product_id INT;
	v_shopping_id INT;
	v_inventory_id INT;
    v_date_purchase DATE;
    v_product_details JSON;
	v_unit_price DECIMAL(10, 2);
BEGIN
    -- Extraer la fecha de compra y el arreglo de productos del JSON
    v_date_purchase := (jsonDetails->>'date_purchase')::DATE;
    v_product_details := jsonDetails->'products';
	
	-- Extraer el product_id del primer producto
    SELECT (json_array_elements(v_product_details)->>'product_id')::INT INTO v_first_product_id FROM json_array_elements(v_product_details) LIMIT 1;
	-- Obtener el supplier_id del primer producto
    SELECT supplier_customer_id INTO v_supplier_id FROM view_products WHERE id = v_first_product_id;
	
    -- Crear la venta y obtener el ID
    INSERT INTO shoppings (supplier_customer_id,date_purchase,created_at,updated_at) 
		VALUES (v_supplier_id,v_date_purchase,NOW(), NOW()) RETURNING id INTO v_shopping_id;
	
    -- Iterar sobre cada objeto en el arreglo de productos
    FOR v_product_details IN SELECT * FROM json_array_elements(v_product_details)
    LOOP
		
		-- Verificar si el product_id existe en la tabla 'view_products'
		IF NOT EXISTS (SELECT 1 FROM view_products WHERE id = (v_product_details->>'product_id')::INT AND supplier_customer_id=v_supplier_id) THEN
			RAISE EXCEPTION 'El producto % no existe con el proveedor con id %',(v_product_details->>'product_id')::INT,v_supplier_id;
		END IF;
		
		SELECT COALESCE(price, 0) INTO v_unit_price FROM view_products WHERE id = (v_product_details->>'product_id')::INT;

		-- Insertar en la tabla 'inventories'
    	INSERT INTO inventories (product_id, quantity,created_at,updated_at) VALUES ((v_product_details->>'product_id')::INT, (v_product_details->>'quantity')::INT, NOW(), NOW()) RETURNING id INTO v_inventory_id;
		
		-- RAISE NOTICE 'INVENTARIO: %', v_inventory_id; 
    	-- Insertar en la tabla 'shoppings' usando el 'inventory_id' obtenido
    	INSERT INTO shopping_details (shopping_id,inventory_id, unit_price,created_at,updated_at) 
			VALUES (v_shopping_id,v_inventory_id, v_unit_price, NOW(), NOW());
    END LOOP;
EXCEPTION
    WHEN others THEN RAISE;-- Manejo de errores
END;
$$;