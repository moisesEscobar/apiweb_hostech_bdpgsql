DROP Function IF EXISTS create_log;
CREATE OR REPLACE FUNCTION public.create_log(p_user_id integer, p_action character varying, p_catalog character varying, p_detail_last jsonb, p_detail_new jsonb)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
        BEGIN
            INSERT INTO logs (user_id, action, catalog, detail_last, detail_new, created_at,updated_at)
            VALUES (p_user_id, p_action, p_catalog, p_detail_last, p_detail_new, NOW(),NOW());
        END;
        $function$
;