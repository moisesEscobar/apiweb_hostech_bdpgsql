-- Active: 1703104882796@@127.0.0.1@5432@hostech@public
DROP PROCEDURE create_product_sale;
CREATE OR REPLACE PROCEDURE public.create_product_sale(IN jsondetails json)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
    v_customer_id INT;
	v_user_id INT;
	v_date_sale DATE;
	v_product_details JSON;
	v_unit_price DECIMAL(10, 2);
	v_product_sale_id INT;
	
	v_product_name VARCHAR;
	v_customer_name VARCHAR;
	v_supplier_name VARCHAR;
	v_modified_details JSONB[] := '{}'; 
	
BEGIN
    -- Extraer los datos de objeto
	v_user_id := (jsonDetails->>'user_id')::INT;
    v_customer_id := (jsonDetails->>'customer_id')::INT;
	v_date_sale := (jsonDetails->>'date_sale')::DATE;
    v_product_details := jsonDetails->'products';
	
	-- Validar payment_type_id
    IF NOT EXISTS (SELECT 1 FROM view_suppliers WHERE id = v_customer_id AND type_user='customer') THEN
        RAISE EXCEPTION 'El usuario % no existe como cliente', v_customer_id;
    END IF;
	-- Obtener el nombre del cliente
	SELECT name INTO v_customer_name FROM view_suppliers WHERE id = v_customer_id;

    -- Crear la venta y obtener el ID
    INSERT INTO product_sales (supplier_customer_id,date_sale,created_at,updated_at) VALUES (v_customer_id,v_date_sale,NOW(), NOW()) RETURNING id INTO v_product_sale_id;
	
    -- Iterar sobre cada objeto en el arreglo de productos
    FOR v_product_details IN SELECT * FROM json_array_elements(v_product_details) LOOP
		-- Verificar si el product_id existe en la tabla 'view_products'
		IF NOT EXISTS (
			SELECT 1 FROM view_products_with_inventory WHERE product_id = (v_product_details->>'product_id')::INT AND quantity_available>=(v_product_details->>'quantity')::INT
		) THEN
			RAISE EXCEPTION 'El producto % no existe o la cantidad disponible no es suficiente.',(v_product_details->>'product_id')::INT;
		END IF;
		-- Obtener el precio unitario del producto al momento de la venta
		SELECT COALESCE(price, 0),supplier_name INTO v_unit_price,v_supplier_name FROM view_products WHERE id = (v_product_details->>'product_id')::INT;

		-- Insertar en la tabla 'inventories'
		INSERT INTO product_sale_details(product_sale_id,product_id,quantity,unit_price,created_at,updated_at) 
			VALUES (
				v_product_sale_id,(v_product_details->>'product_id')::INT, (v_product_details->>'quantity')::INT, v_unit_price,NOW(), NOW()
			);
		
		-- Obtener detalles adicionales como nombres
        SELECT name INTO v_product_name FROM view_products WHERE id = (v_product_details->>'product_id')::INT;
		v_product_details := jsonb_set(v_product_details::jsonb, '{product_name}', to_jsonb(v_product_name));
        v_product_details := jsonb_set(v_product_details::jsonb, '{supplier_name}', to_jsonb(v_supplier_name));
		v_modified_details := array_append(v_modified_details, v_product_details::jsonb);
    END LOOP;
	-- Crear el log de lo realizado
	CALL create_log(
		v_user_id, 'create'::VARCHAR, 'sale'::VARCHAR, null, 
		jsonb_build_object(
			'date_sale', v_date_sale,
			'customer_id', v_customer_id,
			'customer_name', v_customer_name,
			'products', v_modified_details
		)
	);
EXCEPTION WHEN others THEN RAISE;-- Manejo de errores
END;
$procedure$
