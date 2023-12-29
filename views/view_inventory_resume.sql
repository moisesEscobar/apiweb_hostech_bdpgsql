
CREATE
OR REPLACE VIEW public.view_inventory_resume AS
SELECT
    ip.product_id,
    ip.total_quantity,
    COALESCE(ips.quantity_sold, 0 :: bigint) AS quantity_sold,
    COALESCE(
        ips.total_amount,
        0 :: double precision
    ) AS total_amount
FROM (
        SELECT
            inventories.product_id,
            sum(inventories.quantity) AS total_quantity
        FROM inventories
        WHERE
            inventories.deleted_at IS NULL
        GROUP BY
            inventories.product_id
    ) ip
    LEFT JOIN (
        SELECT
            product_sales.product_id,
            sum(product_sales.quantity) AS quantity_sold,
            sum(product_sales.total_amount) AS total_amount
        FROM product_sales
        GROUP BY
            product_sales.product_id
    ) ips ON ip.product_id = ips.product_id;