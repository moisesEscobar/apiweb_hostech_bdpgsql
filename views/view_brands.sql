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