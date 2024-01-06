CREATE OR REPLACE VIEW public.view_products AS
SELECT
    id,
    name,
    sku,
    price,
    reorder_point,
    brand_id, (
        SELECT brands.name
        FROM brands
        WHERE (brands.id = prds.brand_id)
    ) AS brand_name,
    supplier_customer_id, (
        SELECT
            suppliers_customers.name
        FROM
            suppliers_customers
        WHERE (
                suppliers_customers.id = prds.supplier_customer_id
            )
    ) AS supplier_name,
    created_at,
    updated_at,
    path_file,description
FROM products prds
WHERE (deleted_at IS NULL);