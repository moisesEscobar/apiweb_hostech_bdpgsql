CREATE
OR REPLACE VIEW public.view_brands_with_products AS
SELECT
    id,
    name,
    created_at,
    updated_at,
    deleted_at
FROM view_brands vb
WHERE (
        EXISTS (
            SELECT 1
            FROM products
            WHERE
                vb.id = products.brand_id
        )
    );