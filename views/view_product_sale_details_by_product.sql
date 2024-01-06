CREATE OR REPLACE VIEW public.view_product_sale_details_by_product AS
SELECT
    product_id,
    SUM(quantity) quantity_sold,
    SUM(quantity * unit_price) total_amount
FROM product_sale_details
where deleted_at IS NULL
GROUP BY product_id