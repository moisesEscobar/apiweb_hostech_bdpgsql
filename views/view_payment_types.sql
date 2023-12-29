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