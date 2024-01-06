CREATE OR REPLACE VIEW public.view_users AS
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