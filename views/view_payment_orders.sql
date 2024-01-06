CREATE OR REPLACE VIEW public.view_payment_orders AS
SELECT
    vpo.*,
    COALESCE(vpor.total_amount, 0 :: bigint) AS total_amount
FROM payment_orders vpo
LEFT JOIN view_purchase_orders_by_order vpor ON vpor.payment_order_id=vpo.id
WHERE (vpo.deleted_at IS NULL);