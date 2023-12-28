CREATE
OR REPLACE VIEW public.view_suppliers AS
SELECT
    id,
    name,
    phone_number,
    description,
    type_user,
    created_at,
    updated_at,
    deleted_at
FROM suppliers_customers
WHERE (deleted_at IS NULL);

CREATE
OR REPLACE VIEW public.view_payment_orders AS
SELECT
    id,
    status,
    payment_date,
    created_at,
    updated_at,
    deleted_at
FROM payment_orders
WHERE (deleted_at IS NULL);

CREATE
OR REPLACE VIEW public.view_payment_types AS
SELECT
    id,
    name,
    created_at,
    updated_at,
    deleted_at
FROM payment_types
WHERE (deleted_at IS NULL);

CREATE
OR REPLACE VIEW public.view_purchase_orders AS
SELECT
    shopping_id,
    payment_order_id,
    created_at,
    updated_at,
    deleted_at
FROM purchase_orders
WHERE (deleted_at IS NULL);

CREATE
OR REPLACE VIEW public.view_shoppings AS
SELECT
    id,
    inventory_id,
    unit_price,
    created_at,
    updated_at,
    deleted_at
FROM shoppings
WHERE (deleted_at IS NULL);

CREATE
OR REPLACE VIEW public.view_brands AS
SELECT
    id,
    name,
    created_at,
    updated_at,
    deleted_at
FROM brands
WHERE deleted_at IS NULL;

CREATE
OR REPLACE VIEW public.view_products AS
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
    updated_at
FROM products prds
WHERE (deleted_at IS NULL);

CREATE
OR REPLACE VIEW public.view_payment_order_txns AS
SELECT
    id,
    status,
    amount,
    user_id,
    payment_type_id,
    payment_order_id,
    supplier_customer_id,
    created_at,
    updated_at,
    deleted_at
FROM payment_order_txn
WHERE deleted_at IS NULL;

CREATE
OR REPLACE VIEW public.view_users AS
SELECT
    id,
    name,
    last_name,
    second_surname,
    phone_number,
    email,
    password,
    created_at,
    updated_at,
    deleted_at
FROM users
WHERE (deleted_at IS NULL);

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

CREATE
OR REPLACE VIEW public.view_logs AS
SELECT
    lv.id,
    lv.action,
    lv.catalog,
    lv.detail_last,
    lv.detail_new,
    u.id AS user_id,
    u.name AS user_name,
    u.last_name AS user_last_name,
    u.email AS user_email,
    lv.created_at,
    lv.updated_at
FROM logs lv
    JOIN users u ON lv.user_id = u.id
WHERE lv.deleted_at IS NULL
ORDER BY lv.id DESC;

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
        vir.total_amount, (0) :: double precision
    ) AS total_amount
FROM (
        view_products vp
        JOIN view_inventory_resume vir ON ( (vp.id = vir.product_id))
    );

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