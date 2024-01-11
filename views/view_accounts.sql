CREATE OR REPLACE VIEW public.view_accounts AS
SELECT ac.id,
    ac.account_name,
    ac.initial_balance,
    ac.created_at,
    ac.updated_at,
    ac.deleted_at,
    ((ac.initial_balance + vibo.amount) - COALESCE(veba.amount, (0)::double precision)) AS balance,
    COALESCE(vibo.amount, (0)::double precision) AS incomes,
    COALESCE(veba.amount, (0)::double precision) AS expenses,
    (ac.initial_balance + vibo.amount) AS total
   FROM ((accounts ac
     LEFT JOIN view_incomes_by_account vibo ON ((ac.id = vibo.account_id)))
     LEFT JOIN view_expenses_by_account veba ON ((ac.id = veba.account_id)))
  WHERE (ac.deleted_at IS NULL);
