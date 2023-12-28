CREATE
OR REPLACE VIEW public.view_users AS
SELECT
    users.id,
    users.name,
    users.last_name,
    users.second_surname,
    users.email,
    users.password,
    users.created_at,
    users.updated_at,
    users.deleted_at
FROM users
WHERE (users.deleted_at IS NULL);

CREATE
OR REPLACE VIEW public.view_brands AS
SELECT
    brands.id,
    brands.name,
    brands.created_at,
    brands.updated_at,
    brands.deleted_at
FROM brands
WHERE (brands.deleted_at IS NULL);

CREATE
OR REPLACE VIEW public.view_suppliers AS
SELECT
    suppliers.id,
    suppliers.name,
    suppliers.created_at,
    suppliers.updated_at,
    suppliers.deleted_at
FROM suppliers
WHERE (suppliers.deleted_at IS NULL);

CREATE
OR REPLACE VIEW public.view_payment_types AS
SELECT
    payment_types.id,
    payment_types.name,
    payment_types.created_at,
    payment_types.updated_at,
    payment_types.deleted_at
FROM payment_types
WHERE (
        payment_types.deleted_at IS NULL
    );

CREATE
OR REPLACE VIEW public.view_products AS
SELECT
    prds.id,
    prds.name,
    prds.sku,
    prds.price,
    prds.reorder_point,
    prds.brand_id, (
        SELECT brands.name
        FROM brands
        WHERE (brands.id = prds.brand_id)
    ) AS brand_name,
    prds.supplier_id, (
        SELECT suppliers.name
        FROM suppliers
        WHERE (
                suppliers.id = prds.supplier_id
            )
    ) AS supplier_name,
    prds.created_at,
    prds.updated_at
FROM products prds
WHERE (prds.deleted_at IS NULL);

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
FROM (
        logs lv
        JOIN users u ON ( (lv.user_id = u.id))
    )
WHERE (lv.deleted_at IS NULL)
ORDER BY lv.id DESC;

CREATE
OR REPLACE VIEW public.view_brands_with_products AS
SELECT
    vb.id,
    vb.name,
    vb.created_at,
    vb.updated_at,
    vb.deleted_at
FROM view_brands vb
WHERE (
        EXISTS (
            SELECT 1
            FROM products
            WHERE (vb.id = products.brand_id)
        )
    );

CREATE
OR REPLACE VIEW public.view_inventory_resume AS
SELECT
    ip.product_id,
    ip.total_quantity,
    COALESCE(
        ips.quantity_sold, (0) :: bigint
    ) AS quantity_sold,
    COALESCE(ips.total_amount, (0) :: bigint) AS total_amount
FROM ( (
            SELECT
                inventories.product_id,
                sum(inventories.quantity) AS total_quantity
            FROM inventories
            WHERE (inventories.deleted_at IS NULL)
            GROUP BY
                inventories.product_id
        ) ip
        LEFT JOIN (
            SELECT
                product_sales.product_id,
                sum(product_sales.quantity) AS quantity_sold,
                sum(product_sales.total_amount) AS total_amount
            FROM
                product_sales
            GROUP BY
                product_sales.product_id
        ) ips ON ( (ip.product_id = ips.product_id)
        )
    );

CREATE
OR REPLACE VIEW public.view_inventories AS
SELECT
    iv.id,
    vp.supplier_id, (
        SELECT suppliers.name
        FROM suppliers
        WHERE (suppliers.id = vp.supplier_id)
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
FROM (
        inventories iv
        JOIN view_products vp ON ( (iv.product_id = vp.id))
    )
WHERE (iv.deleted_at IS NULL);

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

CREATE
OR REPLACE VIEW public.view_products_with_inventory AS
SELECT
    vp.id AS product_id,
    vp.supplier_id,
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
    COALESCE(vir.total_amount, (0) :: bigint) AS total_amount
FROM (
        view_products vp
        JOIN view_inventory_resume vir ON ( (vp.id = vir.product_id))
    );