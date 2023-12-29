CREATE
OR REPLACE VIEW public.view_payment_orders AS
SELECT
    id,
    status,
    payment_date,
    created_at,
    updated_at,
    deleted_at
FROM payment_orders
WHERE (deleted_at IS NULL);