CREATE OR REPLACE VIEW public.view_purchase_orders_by_shopping AS
SELECT  shopping_id, SUM(amount) total_amount_paid FROM public.purchase_orders WHERE deleted_at IS NULL GROUP BY shopping_id

