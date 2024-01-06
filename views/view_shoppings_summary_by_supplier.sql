CREATE OR REPLACE VIEW public.view_shoppings_summary_by_supplier AS
SELECT
	vs.supplier_customer_id,
	SUM(COALESCE(vsd.quantity_products,0)) total_products,
	SUM(COALESCE(vsd.total_amount_purchase,0)) total_amount_purchase,
	SUM(COALESCE(vpo.total_amount_paid,0)) total_amount_paid,
	SUM(COALESCE(vsd.total_amount_purchase,0) - COALESCE(vpo.total_amount_paid,0)) amount_payable
FROM view_shoppings vs
LEFT JOIN view_shopping_details_by_shopping vsd ON vs.id=vsd.shopping_id
LEFT JOIN view_purchase_orders_by_shopping vpo ON vs.id=vpo.shopping_id
GROUP BY supplier_customer_id