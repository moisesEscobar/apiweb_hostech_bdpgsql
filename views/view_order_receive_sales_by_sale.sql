CREATE OR REPLACE VIEW public.view_order_receive_sales_by_sale AS
SELECT 
	product_sale_id, SUM(amount) total_amount_paid
FROM order_receive_sales WHERE (deleted_at IS NULL)
GROUP BY product_sale_id