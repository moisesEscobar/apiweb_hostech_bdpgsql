--
-- PostgreSQL database dump
--

-- Dumped from database version 16.1
-- Dumped by pg_dump version 16.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: create_log(integer, character varying, character varying, jsonb, jsonb); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.create_log(IN p_user_id integer, IN p_action character varying, IN p_catalog character varying, IN p_detail_last jsonb, IN p_detail_new jsonb)
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO logs (user_id, action, catalog, detail_last, detail_new, created_at,updated_at)
	VALUES (p_user_id, p_action, p_catalog, p_detail_last, p_detail_new, NOW(),NOW());
EXCEPTION
    WHEN others THEN RAISE;-- En caso de error, se revierte la transacci├│n autom├íticamente
END;$$;


ALTER PROCEDURE public.create_log(IN p_user_id integer, IN p_action character varying, IN p_catalog character varying, IN p_detail_last jsonb, IN p_detail_new jsonb);

--
-- Name: create_order_receive_sales(json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.create_order_receive_sales(IN jsondetails json)
    LANGUAGE plpgsql
    AS $$
DECLARE
	v_first_sale_id INT;
    v_customer_id INT;
	v_order_receive_id INT;
	v_date_order DATE; 
    v_sales JSON;
	v_amount_payable DOUBLE PRECISION ;
	
BEGIN
	v_customer_id := (jsonDetails->>'customer_id')::INT;
    v_date_order := (jsonDetails->>'date_order')::DATE;
    v_sales := jsonDetails->'sales';
	
	-- Extraer el customer_id de la venta a partir del id de la primera venta
    SELECT (json_array_elements(v_sales)->>'product_sale_id')::INT INTO v_first_sale_id FROM json_array_elements(v_sales) LIMIT 1;
    SELECT supplier_customer_id INTO v_customer_id FROM view_product_sales WHERE id = v_first_sale_id;
	

    -- Crear la orden de cobro
    INSERT INTO order_receive(supplier_customer_id,date_order,created_at,updated_at) 
		VALUES (v_customer_id,v_date_order,NOW(), NOW()) RETURNING id INTO v_order_receive_id;

    -- Iterar sobre cada objeto en el arreglo de ventas
    FOR v_sales IN SELECT * FROM json_array_elements(v_sales)
    LOOP
		-- RAISE NOTICE 'Procesando producto: %', id;
		-- VALIDAR(las compras sean del mismo cliente,el monto de cada compra sea menor o igual al monto faltante por abonar)
		IF NOT EXISTS (SELECT 1 FROM view_product_sales WHERE id = (v_sales->>'product_sale_id')::INT AND supplier_customer_id=v_customer_id) THEN
			RAISE EXCEPTION 'La venta  % no existe o no pertenece al cliente con id %',(v_sales->>'product_sale_id')::INT,v_customer_id;
		END IF;
		
		SELECT COALESCE(amount_payable, 0) INTO v_amount_payable FROM view_products_sales_summary WHERE id = (v_sales->>'product_sale_id')::INT;
		
		-- Verificar si el amount es menor o igual al saldo por pagar
		IF (v_sales->>'amount')::DOUBLE PRECISION > v_amount_payable THEN
			RAISE EXCEPTION 'El monto de la compra % es mayor que el saldo disponible. Monto de la venta: %, Saldo: %',
								(v_sales->>'product_sale_id')::INT, (v_sales->>'amount')::DOUBLE PRECISION, v_amount_payable;
		END IF;
		
		INSERT INTO order_receive_sales (product_sale_id,amount,order_receive_id,created_at,updated_at) 
			VALUES ((v_sales->>'product_sale_id')::INT,(v_sales->>'amount')::DOUBLE PRECISION, v_order_receive_id,NOW(),NOW());
			
    END LOOP;
EXCEPTION
    WHEN others THEN RAISE;-- Manejo de errores
END;
$$;


ALTER PROCEDURE public.create_order_receive_sales(IN jsondetails json);

--
-- Name: create_payment_order_txns(character varying, integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_payment_order_txns(p_status character varying, p_user_id integer, p_payment_type_id integer, p_payment_order_id integer, p_supplier_customer_id integer) RETURNS json
    LANGUAGE plpgsql
    AS $$
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

    -- Realizar la inserci├│n en payment_order_txns
    INSERT INTO payment_order_txns (user_id, payment_type_id, payment_order_id, supplier_customer_id, status, amount, created_at, updated_at)
    VALUES (p_user_id, p_payment_type_id, p_payment_order_id, p_supplier_customer_id, p_status, v_total_amount, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    RETURNING id INTO v_new_record_id;

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
EXCEPTION
    WHEN others THEN RAISE;
END;
$$;


ALTER FUNCTION public.create_payment_order_txns(p_status character varying, p_user_id integer, p_payment_type_id integer, p_payment_order_id integer, p_supplier_customer_id integer);


--
-- Name: create_payment_orders(json); Type: PROCEDURE; Schema: public; Owner: postgres
--

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


ALTER PROCEDURE public.create_payment_orders(IN jsondetails json);

--
-- Name: create_product_sale(json); Type: PROCEDURE; Schema: public; Owner: postgres
--

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


ALTER PROCEDURE public.create_product_sale(IN jsondetails json);

--
-- Name: create_shopping_and_inventories(json); Type: PROCEDURE; Schema: public; Owner: postgres
--

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


ALTER PROCEDURE public.create_shopping_and_inventories(IN jsondetails json);

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: brands; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.brands (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.brands;

--
-- Name: brands_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.brands_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.brands_id_seq;

--
-- Name: brands_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.brands_id_seq OWNED BY public.brands.id;


--
-- Name: inventories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventories (
    id integer NOT NULL,
    product_id integer NOT NULL,
    quantity integer DEFAULT 0,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.inventories;

--
-- Name: inventories_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inventories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventories_id_seq;

--
-- Name: inventories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inventories_id_seq OWNED BY public.inventories.id;


--
-- Name: logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.logs (
    id integer NOT NULL,
    action character varying(255) NOT NULL,
    catalog character varying(255) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    user_id integer,
    detail_last jsonb,
    detail_new jsonb
);


ALTER TABLE public.logs;

--
-- Name: logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.logs_id_seq;

--
-- Name: logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.logs_id_seq OWNED BY public.logs.id;


--
-- Name: order_receive; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_receive (
    id integer NOT NULL,
    supplier_customer_id integer NOT NULL,
    date_order date NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.order_receive;

--
-- Name: order_receive_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.order_receive_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.order_receive_id_seq;

--
-- Name: order_receive_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.order_receive_id_seq OWNED BY public.order_receive.id;


--
-- Name: order_receive_sales; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_receive_sales (
    product_sale_id integer NOT NULL,
    order_receive_id integer NOT NULL,
    amount double precision NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.order_receive_sales;

--
-- Name: order_receive_txns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_receive_txns (
    id integer NOT NULL,
    status character varying(255) NOT NULL,
    amount double precision DEFAULT '0'::double precision NOT NULL,
    user_id integer,
    payment_type_id integer NOT NULL,
    order_receive_id integer NOT NULL,
    supplier_customer_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.order_receive_txns;

--
-- Name: order_receive_txns_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.order_receive_txns_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.order_receive_txns_id_seq;

--
-- Name: order_receive_txns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.order_receive_txns_id_seq OWNED BY public.order_receive_txns.id;


--
-- Name: payment_order_txns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payment_order_txns (
    id integer NOT NULL,
    status character varying(255) NOT NULL,
    amount double precision DEFAULT '0'::double precision NOT NULL,
    user_id integer,
    payment_type_id integer NOT NULL,
    payment_order_id integer NOT NULL,
    supplier_customer_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.payment_order_txns;

--
-- Name: payment_order_txns_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payment_order_txns_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payment_order_txns_id_seq;

--
-- Name: payment_order_txns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payment_order_txns_id_seq OWNED BY public.payment_order_txns.id;


--
-- Name: payment_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payment_orders (
    id integer NOT NULL,
    status character varying(255),
    payment_date date NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.payment_orders;

--
-- Name: payment_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payment_orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payment_orders_id_seq;

--
-- Name: payment_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payment_orders_id_seq OWNED BY public.payment_orders.id;


--
-- Name: payment_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payment_types (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.payment_types;

--
-- Name: payment_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payment_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payment_types_id_seq;

--
-- Name: payment_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payment_types_id_seq OWNED BY public.payment_types.id;


--
-- Name: product_sale_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_sale_details (
    id integer NOT NULL,
    product_sale_id integer NOT NULL,
    product_id integer NOT NULL,
    quantity integer NOT NULL,
    unit_price double precision NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.product_sale_details;

--
-- Name: product_sale_details_by_product; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.product_sale_details_by_product AS
 SELECT product_id,
    sum(quantity) AS quantity_sold,
    sum(((quantity)::double precision * unit_price)) AS total_amount
   FROM public.product_sale_details
  WHERE (deleted_at IS NULL)
  GROUP BY product_id;


ALTER VIEW public.product_sale_details_by_product;

--
-- Name: product_sale_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_sale_details_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.product_sale_details_id_seq;

--
-- Name: product_sale_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_sale_details_id_seq OWNED BY public.product_sale_details.id;


--
-- Name: product_sales; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_sales (
    id integer NOT NULL,
    supplier_customer_id integer NOT NULL,
    date_sale date NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.product_sales;

--
-- Name: product_sales_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_sales_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.product_sales_id_seq;

--
-- Name: product_sales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_sales_id_seq OWNED BY public.product_sales.id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.products (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    sku character varying(255) NOT NULL,
    price double precision DEFAULT '0'::double precision,
    reorder_point integer DEFAULT 0,
    supplier_customer_id integer NOT NULL,
    brand_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    path_file character varying(255)
);


ALTER TABLE public.products;

--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.products_id_seq;

--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.products_id_seq OWNED BY public.products.id;


--
-- Name: purchase_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.purchase_orders (
    shopping_id integer NOT NULL,
    payment_order_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    amount double precision DEFAULT 0
);


ALTER TABLE public.purchase_orders;

--
-- Name: shopping_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shopping_details (
    id integer NOT NULL,
    inventory_id integer NOT NULL,
    unit_price double precision NOT NULL,
    shopping_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.shopping_details;

--
-- Name: shopping_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.shopping_details_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.shopping_details_id_seq;

--
-- Name: shopping_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.shopping_details_id_seq OWNED BY public.shopping_details.id;


--
-- Name: shoppings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shoppings (
    id integer NOT NULL,
    date_purchase date,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    supplier_customer_id integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.shoppings;

--
-- Name: shoppings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.shoppings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.shoppings_id_seq;

--
-- Name: shoppings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.shoppings_id_seq OWNED BY public.shoppings.id;


--
-- Name: suppliers_customers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.suppliers_customers (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    phone_number character varying(255),
    address text,
    type_user character varying(255) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.suppliers_customers;

--
-- Name: suppliers_customers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.suppliers_customers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.suppliers_customers_id_seq;

--
-- Name: suppliers_customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.suppliers_customers_id_seq OWNED BY public.suppliers_customers.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    last_name character varying(255) NOT NULL,
    second_surname character varying(255) NOT NULL,
    phone_number character varying(255),
    email character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.users;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: view_brands; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_brands AS
 SELECT id,
    name,
    created_at,
    updated_at,
    deleted_at
   FROM public.brands
  WHERE (deleted_at IS NULL);


ALTER VIEW public.view_brands;

--
-- Name: view_brands_with_products; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_brands_with_products AS
 SELECT id,
    name,
    created_at,
    updated_at,
    deleted_at
   FROM public.view_brands vb
  WHERE (EXISTS ( SELECT 1
           FROM public.products
          WHERE (vb.id = products.brand_id)));


ALTER VIEW public.view_brands_with_products;

--
-- Name: view_products; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_products AS
 SELECT id,
    name,
    sku,
    price,
    reorder_point,
    brand_id,
    ( SELECT brands.name
           FROM public.brands
          WHERE (brands.id = prds.brand_id)) AS brand_name,
    supplier_customer_id,
    ( SELECT suppliers_customers.name
           FROM public.suppliers_customers
          WHERE (suppliers_customers.id = prds.supplier_customer_id)) AS supplier_name,
    created_at,
    updated_at,
    path_file,
    description
   FROM public.products prds
  WHERE (deleted_at IS NULL);


ALTER VIEW public.view_products;

--
-- Name: view_inventories; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_inventories AS
 SELECT iv.id,
    vp.supplier_customer_id,
    ( SELECT suppliers_customers.name
           FROM public.suppliers_customers
          WHERE (suppliers_customers.id = vp.supplier_customer_id)) AS supplier_name,
    iv.product_id,
    vp.name,
    vp.sku,
    vp.brand_name,
    iv.quantity,
    vp.price,
    vp.reorder_point,
    iv.created_at,
    iv.updated_at
   FROM (public.inventories iv
     JOIN public.view_products vp ON ((iv.product_id = vp.id)))
  WHERE (iv.deleted_at IS NULL);


ALTER VIEW public.view_inventories;

--
-- Name: view_inventories_by_product; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_inventories_by_product AS
 SELECT product_id,
    sum(quantity) AS total_quantity
   FROM public.inventories
  WHERE (deleted_at IS NULL)
  GROUP BY product_id;


ALTER VIEW public.view_inventories_by_product;

--
-- Name: view_inventory_resume; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_inventory_resume AS
 SELECT ip.product_id,
    ip.total_quantity,
    COALESCE(ips.quantity_sold, (0)::bigint) AS quantity_sold,
    COALESCE(ips.total_amount, (0)::double precision) AS total_amount_sold
   FROM (public.view_inventories_by_product ip
     LEFT JOIN public.product_sale_details_by_product ips ON ((ip.product_id = ips.product_id)));


ALTER VIEW public.view_inventory_resume;

--
-- Name: view_users; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_users AS
 SELECT id,
    name,
    last_name,
    second_surname,
    phone_number,
    email,
    password,
    created_at,
    updated_at,
    deleted_at
   FROM public.users
  WHERE (deleted_at IS NULL);


ALTER VIEW public.view_users;

--
-- Name: view_logs; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_logs AS
 SELECT lv.id,
    lv.action,
    lv.catalog,
    lv.detail_last,
    lv.detail_new,
    u.id AS user_id,
    u.name AS user_name,
    u.last_name AS user_last_name,
    u.email AS user_email,
    lv.created_at,
    lv.updated_at
   FROM (public.logs lv
     JOIN public.view_users u ON ((lv.user_id = u.id)))
  WHERE (lv.deleted_at IS NULL)
  ORDER BY lv.id DESC;


ALTER VIEW public.view_logs;

--
-- Name: view_order_receive_sales_by_order; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_order_receive_sales_by_order AS
 SELECT order_receive_id,
    sum(amount) AS total_amount
   FROM public.order_receive_sales
  WHERE (deleted_at IS NULL)
  GROUP BY order_receive_id;


ALTER VIEW public.view_order_receive_sales_by_order;

--
-- Name: view_order_receive_sales_by_sale; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_order_receive_sales_by_sale AS
 SELECT product_sale_id,
    sum(amount) AS total_amount_paid
   FROM public.order_receive_sales
  WHERE (deleted_at IS NULL)
  GROUP BY product_sale_id;


ALTER VIEW public.view_order_receive_sales_by_sale;

--
-- Name: view_orders_receive; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_orders_receive AS
 SELECT ore.id,
    ore.supplier_customer_id,
    ore.date_order,
    ore.created_at,
    ore.updated_at,
    ore.deleted_at,
    COALESCE(ors.total_amount, ((0)::bigint)::double precision) AS total_amount
   FROM (public.order_receive ore
     LEFT JOIN public.view_order_receive_sales_by_order ors ON ((ors.order_receive_id = ore.id)))
  WHERE (ore.deleted_at IS NULL);


ALTER VIEW public.view_orders_receive;

--
-- Name: view_payment_order_txns; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_payment_order_txns AS
 SELECT id,
    status,
    amount,
    user_id,
    payment_type_id,
    payment_order_id,
    supplier_customer_id,
    created_at,
    updated_at,
    deleted_at
   FROM public.payment_order_txns
  WHERE (deleted_at IS NULL);


ALTER VIEW public.view_payment_order_txns;

--
-- Name: view_purchase_orders_by_order; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_purchase_orders_by_order AS
 SELECT payment_order_id,
    sum(amount) AS total_amount
   FROM public.purchase_orders
  WHERE (deleted_at IS NULL)
  GROUP BY payment_order_id;


ALTER VIEW public.view_purchase_orders_by_order;

--
-- Name: view_payment_orders; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_payment_orders AS
 SELECT vpo.id,
    vpo.status,
    vpo.payment_date,
    vpo.created_at,
    vpo.updated_at,
    vpo.deleted_at,
    COALESCE(vpor.total_amount, ((0)::bigint)::double precision) AS total_amount
   FROM (public.payment_orders vpo
     LEFT JOIN public.view_purchase_orders_by_order vpor ON ((vpor.payment_order_id = vpo.id)))
  WHERE (vpo.deleted_at IS NULL);


ALTER VIEW public.view_payment_orders;

--
-- Name: view_payment_types; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_payment_types AS
 SELECT id,
    name,
    created_at,
    updated_at,
    deleted_at
   FROM public.payment_types
  WHERE (deleted_at IS NULL);


ALTER VIEW public.view_payment_types;

--
-- Name: view_product_sale_details_by_product; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_product_sale_details_by_product AS
 SELECT product_id,
    sum(quantity) AS quantity_sold,
    sum(((quantity)::double precision * unit_price)) AS total_amount
   FROM public.product_sale_details
  WHERE (deleted_at IS NULL)
  GROUP BY product_id;


ALTER VIEW public.view_product_sale_details_by_product;

--
-- Name: view_product_sale_details_by_sale; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_product_sale_details_by_sale AS
 SELECT product_sale_id,
    sum(quantity) AS quantity_sold,
    sum(((quantity)::double precision * unit_price)) AS total_amount
   FROM public.product_sale_details
  WHERE (deleted_at IS NULL)
  GROUP BY product_sale_id;


ALTER VIEW public.view_product_sale_details_by_sale;

--
-- Name: view_product_sales; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_product_sales AS
 SELECT ps.id,
    ps.supplier_customer_id,
    ps.date_sale,
    ps.created_at,
    ps.updated_at,
    ps.deleted_at,
    COALESCE(vpst.quantity_sold, (0)::bigint) AS quantity_sold,
    COALESCE(vpst.total_amount, (0)::double precision) AS total_amount
   FROM (public.product_sales ps
     LEFT JOIN public.view_product_sale_details_by_sale vpst ON ((ps.id = vpst.product_sale_id)));


ALTER VIEW public.view_product_sales;

--
-- Name: view_products_sales_summary_by_customerr; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_products_sales_summary_by_customerr AS
 SELECT vs.supplier_customer_id,
    sum(COALESCE(vsd.quantity_sold, (0)::bigint)) AS total_products,
    sum(COALESCE(vsd.total_amount, (0)::double precision)) AS total_amount_purchase,
    sum(COALESCE(vpo.total_amount_paid, (0)::double precision)) AS total_amount_paid,
    sum((COALESCE(vsd.total_amount, (0)::double precision) - COALESCE(vpo.total_amount_paid, (0)::double precision))) AS amount_payable
   FROM ((public.product_sales vs
     LEFT JOIN public.view_product_sale_details_by_sale vsd ON ((vs.id = vsd.product_sale_id)))
     LEFT JOIN public.view_order_receive_sales_by_sale vpo ON ((vs.id = vpo.product_sale_id)))
  WHERE (vs.deleted_at IS NULL)
  GROUP BY vs.supplier_customer_id;


ALTER VIEW public.view_products_sales_summary_by_customerr;

--
-- Name: view_suppliers; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_suppliers AS
 SELECT id,
    name,
    phone_number,
    address,
    type_user,
    created_at,
    updated_at,
    deleted_at
   FROM public.suppliers_customers
  WHERE (deleted_at IS NULL);


ALTER VIEW public.view_suppliers;

--
-- Name: view_products_sales_customers_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_products_sales_customers_summary AS
 SELECT vs.id,
    vs.name,
    vs.phone_number,
    vs.address,
    vs.type_user,
    vss.supplier_customer_id,
    vss.total_products,
    vss.total_amount_purchase,
    vss.total_amount_paid,
    vss.amount_payable,
    vs.created_at,
    vs.updated_at,
    vs.deleted_at
   FROM (public.view_suppliers vs
     LEFT JOIN public.view_products_sales_summary_by_customerr vss ON ((vs.id = vss.supplier_customer_id)))
  WHERE ((vs.type_user)::text = 'customer'::text);


ALTER VIEW public.view_products_sales_customers_summary;

--
-- Name: view_products_sales_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_products_sales_summary AS
 SELECT vps.id,
    vps.supplier_customer_id,
    ( SELECT view_suppliers.name
           FROM public.view_suppliers
          WHERE (view_suppliers.id = vps.supplier_customer_id)) AS customer_name,
    COALESCE(psd.quantity_sold, (0)::bigint) AS quantity_products,
    COALESCE(psd.total_amount, (0)::double precision) AS total_amount,
    COALESCE(vpo.total_amount_paid, (0)::double precision) AS total_amount_paid,
    (COALESCE(psd.total_amount, (0)::double precision) - COALESCE(vpo.total_amount_paid, (0)::double precision)) AS amount_payable,
    vps.date_sale,
    vps.created_at,
    vps.updated_at
   FROM ((public.view_product_sales vps
     LEFT JOIN public.view_product_sale_details_by_sale psd ON ((vps.id = psd.product_sale_id)))
     LEFT JOIN public.view_order_receive_sales_by_sale vpo ON ((vps.id = vpo.product_sale_id)));


ALTER VIEW public.view_products_sales_summary;

--
-- Name: view_products_with_inventory; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_products_with_inventory AS
 SELECT vp.id AS product_id,
    vp.supplier_customer_id,
    vp.supplier_name,
    vp.name AS product_name,
    vp.sku AS product_sku,
    vp.brand_id,
    vp.brand_name,
    vp.price AS product_price,
    vp.reorder_point AS product_reorder_point,
    vir.total_quantity,
    vir.quantity_sold,
    (vir.total_quantity - vir.quantity_sold) AS quantity_available,
    COALESCE(vir.total_amount_sold, (0)::double precision) AS total_amount_sold
   FROM (public.view_products vp
     JOIN public.view_inventory_resume vir ON ((vp.id = vir.product_id)));


ALTER VIEW public.view_products_with_inventory;

--
-- Name: view_purchase_orders; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_purchase_orders AS
 SELECT shopping_id,
    amount,
    payment_order_id,
    created_at,
    updated_at,
    deleted_at
   FROM public.purchase_orders
  WHERE (deleted_at IS NULL);


ALTER VIEW public.view_purchase_orders;

--
-- Name: view_purchase_orders_by_shopping; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_purchase_orders_by_shopping AS
 SELECT shopping_id,
    sum(amount) AS total_amount_paid
   FROM public.purchase_orders
  WHERE (deleted_at IS NULL)
  GROUP BY shopping_id;


ALTER VIEW public.view_purchase_orders_by_shopping;

--
-- Name: view_shopping_details_by_shopping; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_shopping_details_by_shopping AS
 SELECT vsd.shopping_id,
    sum(vi.quantity) AS quantity_products,
    sum(((vi.quantity)::double precision * vsd.unit_price)) AS total_amount_purchase
   FROM (public.shopping_details vsd
     LEFT JOIN public.view_inventories vi ON ((vsd.inventory_id = vi.id)))
  WHERE (vsd.deleted_at IS NULL)
  GROUP BY vsd.shopping_id;


ALTER VIEW public.view_shopping_details_by_shopping;

--
-- Name: view_shoppings; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_shoppings AS
 SELECT id,
    supplier_customer_id,
    date_purchase,
    created_at,
    updated_at,
    deleted_at
   FROM public.shoppings
  WHERE (deleted_at IS NULL);


ALTER VIEW public.view_shoppings;

--
-- Name: view_shoppings_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_shoppings_summary AS
 SELECT vs.id,
    vs.supplier_customer_id,
    ( SELECT view_suppliers.name
           FROM public.view_suppliers
          WHERE (view_suppliers.id = vs.supplier_customer_id)) AS supplier_name,
    COALESCE(vsd.quantity_products, (0)::bigint) AS quantity_products,
    COALESCE(vsd.total_amount_purchase, (0)::double precision) AS total_amount_purchase,
    COALESCE(vpo.total_amount_paid, (0)::double precision) AS total_amount_paid,
    (COALESCE(vsd.total_amount_purchase, (0)::double precision) - COALESCE(vpo.total_amount_paid, (0)::double precision)) AS amount_payable,
    vs.date_purchase,
    vs.created_at,
    vs.updated_at
   FROM ((public.view_shoppings vs
     LEFT JOIN public.view_shopping_details_by_shopping vsd ON ((vs.id = vsd.shopping_id)))
     LEFT JOIN public.view_purchase_orders_by_shopping vpo ON ((vs.id = vpo.shopping_id)));


ALTER VIEW public.view_shoppings_summary;

--
-- Name: view_shoppings_summary_by_supplier; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_shoppings_summary_by_supplier AS
 SELECT vs.supplier_customer_id,
    sum(COALESCE(vsd.quantity_products, (0)::bigint)) AS total_products,
    sum(COALESCE(vsd.total_amount_purchase, (0)::double precision)) AS total_amount_purchase,
    sum(COALESCE(vpo.total_amount_paid, (0)::double precision)) AS total_amount_paid,
    sum((COALESCE(vsd.total_amount_purchase, (0)::double precision) - COALESCE(vpo.total_amount_paid, (0)::double precision))) AS amount_payable
   FROM ((public.view_shoppings vs
     LEFT JOIN public.view_shopping_details_by_shopping vsd ON ((vs.id = vsd.shopping_id)))
     LEFT JOIN public.view_purchase_orders_by_shopping vpo ON ((vs.id = vpo.shopping_id)))
  GROUP BY vs.supplier_customer_id;


ALTER VIEW public.view_shoppings_summary_by_supplier;

--
-- Name: view_shoppings_suppliers_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_shoppings_suppliers_summary AS
 SELECT vs.id,
    vs.name,
    vs.phone_number,
    vs.address,
    vs.type_user,
    vs.created_at,
    vs.updated_at,
    vs.deleted_at,
    vss.supplier_customer_id,
    vss.total_products,
    vss.total_amount_purchase,
    vss.total_amount_paid,
    vss.amount_payable
   FROM (public.view_suppliers vs
     LEFT JOIN public.view_shoppings_summary_by_supplier vss ON ((vs.id = vss.supplier_customer_id)))
  WHERE ((vs.type_user)::text = 'supplier'::text);


ALTER VIEW public.view_shoppings_suppliers_summary;

--
-- Name: brands id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.brands ALTER COLUMN id SET DEFAULT nextval('public.brands_id_seq'::regclass);


--
-- Name: inventories id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventories ALTER COLUMN id SET DEFAULT nextval('public.inventories_id_seq'::regclass);


--
-- Name: logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.logs ALTER COLUMN id SET DEFAULT nextval('public.logs_id_seq'::regclass);


--
-- Name: order_receive id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_receive ALTER COLUMN id SET DEFAULT nextval('public.order_receive_id_seq'::regclass);


--
-- Name: order_receive_txns id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_receive_txns ALTER COLUMN id SET DEFAULT nextval('public.order_receive_txns_id_seq'::regclass);


--
-- Name: payment_order_txns id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_order_txns ALTER COLUMN id SET DEFAULT nextval('public.payment_order_txns_id_seq'::regclass);


--
-- Name: payment_orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_orders ALTER COLUMN id SET DEFAULT nextval('public.payment_orders_id_seq'::regclass);


--
-- Name: payment_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_types ALTER COLUMN id SET DEFAULT nextval('public.payment_types_id_seq'::regclass);


--
-- Name: product_sale_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_sale_details ALTER COLUMN id SET DEFAULT nextval('public.product_sale_details_id_seq'::regclass);


--
-- Name: product_sales id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_sales ALTER COLUMN id SET DEFAULT nextval('public.product_sales_id_seq'::regclass);


--
-- Name: products id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- Name: shopping_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shopping_details ALTER COLUMN id SET DEFAULT nextval('public.shopping_details_id_seq'::regclass);


--
-- Name: shoppings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shoppings ALTER COLUMN id SET DEFAULT nextval('public.shoppings_id_seq'::regclass);


--
-- Name: suppliers_customers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.suppliers_customers ALTER COLUMN id SET DEFAULT nextval('public.suppliers_customers_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: brands brands_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.brands
    ADD CONSTRAINT brands_pkey PRIMARY KEY (id);


--
-- Name: inventories inventories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventories
    ADD CONSTRAINT inventories_pkey PRIMARY KEY (id);


--
-- Name: order_receive order_receive_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_receive
    ADD CONSTRAINT order_receive_pkey PRIMARY KEY (id);


--
-- Name: order_receive_sales order_receive_sales_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_receive_sales
    ADD CONSTRAINT order_receive_sales_pkey PRIMARY KEY (product_sale_id, order_receive_id);


--
-- Name: order_receive_txns order_receive_txns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_receive_txns
    ADD CONSTRAINT order_receive_txns_pkey PRIMARY KEY (id);


--
-- Name: payment_order_txns payment_order_txns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_order_txns
    ADD CONSTRAINT payment_order_txns_pkey PRIMARY KEY (id);


--
-- Name: payment_orders payment_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_orders
    ADD CONSTRAINT payment_orders_pkey PRIMARY KEY (id);


--
-- Name: payment_types payment_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_types
    ADD CONSTRAINT payment_types_pkey PRIMARY KEY (id);


--
-- Name: product_sale_details product_sale_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_sale_details
    ADD CONSTRAINT product_sale_details_pkey PRIMARY KEY (id);


--
-- Name: product_sales product_sales_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_sales
    ADD CONSTRAINT product_sales_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: purchase_orders purchase_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchase_orders_pkey PRIMARY KEY (shopping_id, payment_order_id);


--
-- Name: shopping_details shopping_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shopping_details
    ADD CONSTRAINT shopping_details_pkey PRIMARY KEY (id);


--
-- Name: shoppings shoppings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shoppings
    ADD CONSTRAINT shoppings_pkey PRIMARY KEY (id);


--
-- Name: suppliers_customers suppliers_customers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.suppliers_customers
    ADD CONSTRAINT suppliers_customers_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_products_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_products_brand_id ON public.products USING btree (brand_id);


--
-- PostgreSQL database dump complete
--

