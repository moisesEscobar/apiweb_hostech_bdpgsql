CREATE
OR REPLACE VIEW public.view_suppliers AS
SELECT
    id,
    name,
    phone_number,
    address,
    type_user,
    created_at,
    updated_at,
    deleted_at
FROM suppliers_customers
WHERE (deleted_at IS NULL);