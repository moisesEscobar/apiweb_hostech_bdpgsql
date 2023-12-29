CREATE
OR REPLACE VIEW public.view_inventories AS
SELECT
    iv.id,
    vp.supplier_customer_id, (
        SELECT
            suppliers_customers.name
        FROM
            suppliers_customers
        WHERE
            suppliers_customers.id = vp.supplier_customer_id
    ) AS supplier_name,
    iv.product_id,
    vp.name,
    vp.sku,
    vp.brand_name,
    iv.quantity,
    vp.price,
    vp.reorder_point,
    iv.created_at,
    iv.updated_at
FROM inventories iv
    JOIN view_products vp ON iv.product_id = vp.id
WHERE iv.deleted_at IS NULL;