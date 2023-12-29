
-- DROP PROCEDURE IF EXISTS create_log;
CREATE OR REPLACE PROCEDURE public.create_log(IN p_user_id integer, IN p_action character varying, IN p_catalog character varying, IN p_detail_last jsonb, IN p_detail_new jsonb)
LANGUAGE plpgsql
AS $procedure$
BEGIN
	INSERT INTO logs (user_id, action, catalog, detail_last, detail_new, created_at,updated_at)
	VALUES (p_user_id, p_action, p_catalog, p_detail_last, p_detail_new, NOW(),NOW());
EXCEPTION
    WHEN others THEN RAISE;-- En caso de error, se revierte la transacción automáticamente
END;$procedure$
;