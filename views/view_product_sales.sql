CREATE
OR REPLACE VIEW public.view_product_sales AS
SELECT
    ps.id,
    ps.product_id,
    vp.name,
    vp.sku,
    vp.brand_name,
    ps.quantity AS quantity_sold,
    ps.total_amount,
    ps.created_at,
    ps.updated_at
FROM (
        product_sales ps
        JOIN view_products vp ON ( (ps.product_id = vp.id))
    )
WHERE (ps.deleted_at IS NULL);