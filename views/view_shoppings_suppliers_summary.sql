CREATE OR REPLACE VIEW public.view_shoppings_suppliers_summary AS
SELECT vs.id,
    vs.name,
    vs.phone_number,
    vs.address,
    vs.type_user,
    vs.created_at,
    vs.updated_at,
    vs.deleted_at,
    vss.supplier_customer_id,
    vss.total_products,
    vss.total_amount_purchase,
    vss.total_amount_paid,
    vss.amount_payable
FROM (view_suppliers vs
LEFT JOIN view_shoppings_summary_by_supplier vss ON ((vs.id = vss.supplier_customer_id)))
WHERE ((vs.type_user)::text = ANY ((ARRAY['supplier'::character varying, 'both'::character varying])::text[]));
