CREATE
OR REPLACE VIEW public.view_shoppings_inventories AS
SELECT
    vsh.id AS shopping_id,
    vsh.inventory_id,
    vsh.unit_price,
    vi.supplier_customer_id,
    vi.supplier_name,
    vi.product_id,
    vi.name AS product_name,
    vi.sku AS product_sku,
    vi.brand_name,
    vi.quantity AS product_quantity, ( (vi.quantity) :: double precision * vsh.unit_price
    ) AS total_amount
FROM (
        view_shoppings vsh
        JOIN view_inventories vi ON ( (vsh.inventory_id = vi.id))
    );