
-- DROP PROCEDURE create_incomes;
CREATE OR REPLACE PROCEDURE public.create_incomes(IN p_user_id integer, IN p_order_receive_id integer, IN p_account_id integer, IN p_amount double precision)
LANGUAGE plpgsql AS $procedure$
DECLARE v_amount_order INT;
	v_type_action VARCHAR;
	v_account_name VARCHAR;
BEGIN
    -- Validar la existencia de la cuenta
    IF NOT EXISTS (SELECT 1 FROM accounts WHERE id = p_account_id AND deleted_at IS NULL) THEN
        RAISE EXCEPTION 'La cuenta con el id % no existe', p_account_id;
    END IF;

	IF p_order_receive_id IS NOT NULL THEN
		-- Validar la existencia de la orden
		IF NOT EXISTS (SELECT 1 FROM order_receive WHERE id = p_order_receive_id AND deleted_at IS NULL) THEN
			RAISE EXCEPTION 'La orden con el id % no existe', p_order_receive_id;
		END IF;
		-- Validar que solo sea de uno a uno con las ordenes
		IF EXISTS (SELECT 1 FROM incomes WHERE order_receive_id = p_order_receive_id AND deleted_at IS NULL) THEN
			RAISE EXCEPTION 'La orden con el id % ya ha sido registrada como una entrada', p_order_receive_id;
		END IF;
		-- Obtener y validar el monto
		SELECT total_amount INTO v_amount_order FROM view_orders_receive WHERE id = p_order_receive_id;
		IF (p_amount IS NOT NULL  AND  (v_amount_order <> p_amount)) THEN
            RAISE EXCEPTION 'El monto obtenido de la orden ($% MXN) es diferente al monto ingresado ($% MXN)', v_amount_order, p_amount;
        END IF;
		-- Identificar el tipo del movimiento
		IF (p_amount IS NULL)  THEN
			v_type_action := 'ingreso automático';
		ELSE
			v_type_action := 'ingreso manual con orden';
        END IF;
	ELSE
        v_amount_order := p_amount; -- Tomar el monto del parámetro
		v_type_action := 'ingreso manual sin orden';
    END IF;
	
	-- Obtener el saldo o balance y el nombre de la cuenta disponible de la cuenta
    SELECT account_name INTO v_account_name FROM view_accounts WHERE id = p_account_id;

    -- Realizar la inserción en la tabla incomes
    INSERT INTO incomes (order_receive_id, account_id, amount, created_at, updated_at) VALUES (p_order_receive_id, p_account_id, p_amount, NOW(), NOW());
	-- Crear el log de lo realizado
	CALL create_log(
		p_user_id,'create','income',null,
		jsonb_build_object(
			'order_receive_id', p_order_receive_id,
			'account_id', p_account_id,
			'account_name',v_account_name,
			'amount', p_amount,
			'type', v_type_action
		)
	);
	EXCEPTION WHEN others THEN RAISE;
END;
$procedure$
