CREATE
OR
REPLACE
    VIEW public.view_suppliers_types_user AS
SELECT
    id,
    name,
    type_user,
    CASE
        WHEN ( (type_1 IS NULL)
            AND (type_2 IS NULL)
        ) THEN 'supplier,customer,both':: text
        WHEN ( (type_1 IS NULL)
            AND (type_2 IS NOT NULL)
        ) THEN 'customer,both':: text
        WHEN ( (type_2 IS NULL)
            AND (type_1 IS NOT NULL)
        ) THEN 'supplier,both':: text
        WHEN ( (type_1 IS NOT NULL)
            AND (type_2 IS NOT NULL)
        ) THEN 'both':: text
        ELSE NULL:: text
    END AS can_be
FROM (
        SELECT
            vs.id,
            vs.name,
            vs.type_user,
            CASE
                WHEN (
                    vps.supplier_customer_id IS NOT NULL
                ) THEN 'customer':: text
                ELSE NULL:: text
            END AS type_1,
            CASE
                WHEN ( (
                        vp.supplier_customer_id IS NOT NULL
                    )
                    OR (
                        vsh.supplier_customer_id IS NOT NULL
                    )
                ) THEN 'supplier':: text
                ELSE NULL:: text
            END AS type_2
        FROM ( ( (
                        view_suppliers vs
                        LEFT JOIN (
                            SELECT
                                product_sales.supplier_customer_id,
                                count(*) AS count
                            FROM
                                product_sales
                            WHERE (
                                    product_sales.deleted_at IS NULL
                                )
                            GROUP BY
                                product_sales.supplier_customer_id
                        ) vps ON ( (
                                vs.id = vps.supplier_customer_id
                            )
                        )
                    )
                    LEFT JOIN (
                        SELECT
                            products.supplier_customer_id,
                            count(*) AS count
                        FROM
                            products
                        WHERE (products.deleted_at IS NULL)
                        GROUP BY
                            products.supplier_customer_id
                    ) vp ON ( (
                            vs.id = vp.supplier_customer_id
                        )
                    )
                )
                LEFT JOIN (
                    SELECT
                        shoppings.supplier_customer_id,
                        count(*) AS count
                    FROM
                        shoppings
                    WHERE (shoppings.deleted_at IS NULL)
                    GROUP BY
                        shoppings.supplier_customer_id
                ) vsh ON ( (
                        vs.id = vsh.supplier_customer_id
                    )
                )
            )
    ) unnamed_subquery;