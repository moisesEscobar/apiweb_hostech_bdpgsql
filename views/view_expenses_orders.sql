CREATE
OR
REPLACE
    VIEW public.view_expenses_orders AS
SELECT
    e.id,
    e.payment_order_id AS order_id,
    e.account_id,
    e.amount,
    'expense':: text AS type,
    vpo.payment_date AS date_order,
    NULL:: integer AS supplier_customer_id,
    e.created_at,
    e.updated_at
FROM (
        expenses e
        LEFT JOIN view_payment_orders vpo ON ( (e.payment_order_id = vpo.id))
    )
WHERE (e.deleted_at IS NULL);