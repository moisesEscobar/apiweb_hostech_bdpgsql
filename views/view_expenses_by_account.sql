CREATE OR REPLACE VIEW public.view_expenses_by_account AS
SELECT account_id,     sum(amount) AS amount    FROM expenses   WHERE (deleted_at IS NULL)   GROUP BY account_id;