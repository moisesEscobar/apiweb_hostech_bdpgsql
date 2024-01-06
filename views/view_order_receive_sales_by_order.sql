CREATE OR REPLACE VIEW public.view_order_receive_sales_by_order AS
SELECT order_receive_id,SUM(amount) total_amount FROM order_receive_sales WHERE deleted_at IS NULL   GROUP BY order_receive_id