CREATE OR REPLACE VIEW public.view_product_sales AS
SELECT 
	ps.*,
	COALESCE(quantity_sold, 0) quantity_sold,
	COALESCE(total_amount, 0) total_amount
FROM product_sales ps
LEFT JOIN view_product_sale_details_by_sale vpst ON ps.id=vpst.product_sale_id