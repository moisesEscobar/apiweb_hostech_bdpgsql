CREATE OR REPLACE VIEW public.view_inventories_by_product AS
SELECT
    inventories.product_id,
    sum(inventories.quantity) AS total_quantity
FROM inventories
WHERE
    inventories.deleted_at IS NULL
GROUP BY inventories.product_id

