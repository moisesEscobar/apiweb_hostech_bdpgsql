CREATE
OR
REPLACE
    VIEW public.view_incomes_by_account AS
SELECT
    account_id,
    sum(amount) AS amount
FROM incomes
WHERE (deleted_at IS NULL)
GROUP BY account_id;