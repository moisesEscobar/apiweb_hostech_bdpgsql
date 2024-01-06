CREATE OR REPLACE VIEW public.view_inventory_resume AS
SELECT
    ip.product_id,
    ip.total_quantity,
    COALESCE(ips.quantity_sold, 0 :: bigint) AS quantity_sold,
    COALESCE(
        ips.total_amount,
        0 :: double precision
    ) AS total_amount_sold
FROM view_inventories_by_product ip
LEFT JOIN product_sale_details_by_product ips ON ip.product_id = ips.product_id;