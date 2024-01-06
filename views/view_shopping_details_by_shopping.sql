CREATE OR REPLACE VIEW public.view_shopping_details_by_shopping AS
SELECT 
	vsd.shopping_id,
	SUM(vi.quantity) quantity_products,
	SUM(vi.quantity*vsd.unit_price) total_amount_purchase
FROM shopping_details vsd
LEFT JOIN view_inventories vi ON vsd.inventory_id=vi.id
WHERE vsd.deleted_at IS NULL
GROUP BY shopping_id;