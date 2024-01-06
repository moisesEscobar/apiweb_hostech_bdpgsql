CREATE OR REPLACE VIEW public.view_products_sales_summary AS
SELECT 
	vps.id,
	vps.supplier_customer_id,
	(SELECT name FROM view_suppliers WHERE id=vps.supplier_customer_id) customer_name,
	COALESCE(psd.quantity_sold,0) quantity_products,
	COALESCE(psd.total_amount,0) total_amount,
	COALESCE(total_amount_paid,0) total_amount_paid,
	(COALESCE(psd.total_amount,0) - COALESCE(total_amount_paid,0)) amount_payable,
	vps.date_sale,
	vps.created_at,
	vps.updated_at
from view_product_sales vps
LEFT JOIN view_product_sale_details_by_sale psd ON vps.id=psd.product_sale_id
LEFT JOIN view_order_receive_sales_by_sale vpo ON vps.id=vpo.product_sale_id;