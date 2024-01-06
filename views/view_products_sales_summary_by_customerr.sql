CREATE OR REPLACE VIEW public.view_products_sales_summary_by_customerr AS
SELECT
	vs.supplier_customer_id,
	SUM(COALESCE(vsd.quantity_sold,0)) total_products,
	SUM(COALESCE(vsd.total_amount,0)) total_amount_purchase,
	SUM(COALESCE(vpo.total_amount_paid,0)) total_amount_paid,
	SUM(COALESCE(vsd.total_amount,0) - COALESCE(vpo.total_amount_paid,0)) amount_payable
FROM product_sales vs
LEFT JOIN view_product_sale_details_by_sale vsd ON vs.id=vsd.product_sale_id
LEFT JOIN view_order_receive_sales_by_sale vpo ON vs.id=vpo.product_sale_id
WHERE vs.deleted_at IS NULL
GROUP BY supplier_customer_id
