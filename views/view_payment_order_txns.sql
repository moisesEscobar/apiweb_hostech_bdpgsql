
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
FROM payment_order_txns
WHERE deleted_at IS NULL;