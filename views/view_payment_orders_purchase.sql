CREATE
OR REPLACE VIEW public.view_payment_orders_purchase AS
SELECT
    vpu.payment_order_id,
    vpo.status,
    vpo.payment_date,
    vsi.shopping_id,
    vsi.inventory_id,
    vsi.unit_price,
    vsi.supplier_customer_id,
    vsi.supplier_name,
    vsi.product_id,
    vsi.product_name,
    vsi.product_sku,
    vsi.brand_name,
    vsi.product_quantity,
    vsi.total_amount
FROM ( (
            view_purchase_orders vpu
            JOIN view_payment_orders vpo ON ( (vpu.payment_order_id = vpo.id)
            )
        )
        JOIN view_shoppings_inventories vsi ON ( (
                vpu.shopping_id = vsi.shopping_id
            )
        )
    );