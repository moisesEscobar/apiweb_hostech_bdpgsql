CREATE
OR REPLACE VIEW public.view_logs AS
SELECT
    lv.id,
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
FROM logs lv
    JOIN users u ON lv.user_id = u.id
WHERE lv.deleted_at IS NULL
ORDER BY lv.id DESC;