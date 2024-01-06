CREATE
OR REPLACE VIEW public.view_products_with_inventory AS
SELECT
    vp.id AS product_id,
    vp.supplier_customer_id,
    vp.supplier_name,
    vp.name AS product_name,
    vp.sku AS product_sku,
    vp.brand_id,
    vp.brand_name,
    vp.price AS product_price,
    vp.reorder_point AS product_reorder_point,
    vir.total_quantity,
    vir.quantity_sold, (
        vir.total_quantity - vir.quantity_sold
    ) AS quantity_available,
    COALESCE(
        vir.total_amount_sold, (0) :: double precision
    ) AS total_amount_sold
FROM (
        view_products vp
        JOIN view_inventory_resume vir ON ( (vp.id = vir.product_id))
    );
