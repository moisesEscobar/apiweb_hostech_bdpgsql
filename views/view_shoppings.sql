CREATE OR REPLACE VIEW public.view_shoppings AS
 SELECT id,
    supplier_customer_id,
    date_purchase,
    created_at,
    updated_at,
    deleted_at
   FROM shoppings
  WHERE (deleted_at IS NULL);