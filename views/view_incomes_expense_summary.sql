CREATE
OR
REPLACE
    VIEW public.view_incomes_expense_summary AS
SELECT
    vs.name AS supplier_name,
    vs.type_user,
    vac.account_name,
    va.id,
    va.order_id,
    va.account_id,
    va.amount,
    va.type,
    va.date_order,
    va.supplier_customer_id,
    va.created_at,
    va.updated_at
FROM ( ( (
                SELECT
                    view_incomes_orders.id,
                    view_incomes_orders.order_id,
                    view_incomes_orders.account_id,
                    view_incomes_orders.amount,
                    view_incomes_orders.type,
                    view_incomes_orders.date_order,
                    view_incomes_orders.supplier_customer_id,
                    view_incomes_orders.created_at,
                    view_incomes_orders.updated_at
                FROM
                    view_incomes_orders
                UNION ALL
                SELECT
                    view_expenses_orders.id,
                    view_expenses_orders.order_id,
                    view_expenses_orders.account_id,
                    view_expenses_orders.amount,
                    view_expenses_orders.type,
                    view_expenses_orders.date_order,
                    view_expenses_orders.supplier_customer_id,
                    view_expenses_orders.created_at,
                    view_expenses_orders.updated_at
                FROM
                    view_expenses_orders
            ) va
            LEFT JOIN view_suppliers vs ON ( (
                    va.supplier_customer_id = vs.id
                )
            )
        )
        LEFT JOIN view_accounts vac ON ( (va.account_id = vac.id))
    );