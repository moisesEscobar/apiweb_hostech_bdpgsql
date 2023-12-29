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