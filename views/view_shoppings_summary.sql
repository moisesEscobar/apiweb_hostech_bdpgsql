CREATE OR REPLACE VIEW public.view_shoppings_summary AS
	SELECT
		id,
		vs.supplier_customer_id,
		(SELECT name FROM view_suppliers WHERE id=vs.supplier_customer_id) supplier_name,
		COALESCE(vsd.quantity_products,0) quantity_products,
		COALESCE(vsd.total_amount_purchase,0) total_amount_purchase,
		COALESCE(total_amount_paid,0) total_amount_paid,
		(COALESCE(vsd.total_amount_purchase,0) - COALESCE(total_amount_paid,0)) amount_payable,
		date_purchase,
		created_at,
		updated_at
	FROM view_shoppings vs
	LEFT JOIN view_shopping_details_by_shopping vsd ON vs.id=vsd.shopping_id
	LEFT JOIN view_purchase_orders_by_shopping vpo ON vs.id=vpo.shopping_id
