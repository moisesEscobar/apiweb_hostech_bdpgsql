CREATE OR REPLACE VIEW public.view_products_sales_customers_summary AS
SELECT vs.id,
    vs.name,
    vs.phone_number,
    vs.address,
    vs.type_user,
    vss.supplier_customer_id,
    vss.total_products,
    vss.total_amount_purchase,
    vss.total_amount_paid,
    vss.amount_payable,
	vs.created_at,
    vs.updated_at,
    vs.deleted_at
FROM (view_suppliers vs
LEFT JOIN view_products_sales_summary_by_customerr vss ON ((vs.id = vss.supplier_customer_id)))
WHERE (vs.type_user)::text  IN ('customer');