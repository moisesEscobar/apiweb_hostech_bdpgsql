CREATE OR REPLACE VIEW public.view_orders_receive AS
SELECT
    ore.*,
    COALESCE(ors.total_amount, 0 :: bigint) AS total_amount
FROM order_receive ore
LEFT JOIN view_order_receive_sales_by_order ors ON ors.order_receive_id=ore.id
WHERE (ore.deleted_at IS NULL);