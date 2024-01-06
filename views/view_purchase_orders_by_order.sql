CREATE OR REPLACE VIEW public.view_purchase_orders_by_order AS
SELECT payment_order_id, SUM(amount) total_amount FROM purchase_orders WHERE (deleted_at IS NULL) GROUP BY payment_order_id;