CREATE
OR
REPLACE
    VIEW public.view_incomes_orders AS
SELECT
    i.id,
    i.order_receive_id AS order_id,
    i.account_id,
    i.amount,
    'income':: text AS type,
    vor.date_order,
    vor.supplier_customer_id,
    i.created_at,
    i.updated_at
FROM (
        incomes i
        LEFT JOIN view_orders_receive vor ON ( (i.order_receive_id = vor.id))
    )
WHERE (i.deleted_at IS NULL);