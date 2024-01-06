CREATE
OR REPLACE VIEW public.view_purchase_orders AS
SELECT
    shopping_id,
    amount,
    payment_order_id,
    created_at,
    updated_at,
    deleted_at
FROM purchase_orders
WHERE (deleted_at IS NULL);