-- Tag id 518218b9-23bf-4394-bf58-41d47835aeaf = Recurrency - Monthly

WITH to_duplicate AS (
  SELECT
    t.id AS old_transaction_id,
    t.category_id,
    t.merchant_id,
    t.locked_attributes,
    t.kind,
    e.id AS old_entry_id,
    e.account_id,
    e.amount,
    e.currency,
    e.date,
    e.name,
    e.notes,
    e.excluded,
    e.plaid_id,
    e.locked_attributes AS entry_locked_attributes,
    (e.date + INTERVAL '1 month')::date AS new_date
  FROM transactions t
  JOIN taggings tg ON tg.taggable_id = t.id AND tg.taggable_type = 'Transaction'
  JOIN entries e ON e.entryable_id = t.id AND e.entryable_type = 'Transaction'
  WHERE tg.tag_id = '518218b9-23bf-4394-bf58-41d47835aeaf'
),
filtered AS (
  SELECT td.*
  FROM to_duplicate td
  LEFT JOIN entries e2
    ON e2.entryable_type = 'Transaction'
    AND e2.account_id = td.account_id
    AND e2.amount = td.amount
    AND date_trunc('month', e2.date) = date_trunc('month', td.new_date)
  WHERE e2.id IS NULL
    AND td.new_date < date_trunc('month', CURRENT_DATE + INTERVAL '1 month')::date
),
inserted_transactions AS (
  INSERT INTO transactions (id, created_at, updated_at, category_id, merchant_id, locked_attributes, kind)
  SELECT
    gen_random_uuid(),
    now(),
    now(),
    category_id,
    merchant_id,
    locked_attributes,
    kind
  FROM filtered
  RETURNING id
)
INSERT INTO entries (
  id, account_id, entryable_type, entryable_id,
  amount, currency, date, name,
  created_at, updated_at, notes, excluded, plaid_id, locked_attributes
)
SELECT
  gen_random_uuid(),
  f.account_id,
  'Transaction',
  it.id,
  f.amount,
  f.currency,
  f.new_date,
  f.name,
  now(),
  now(),
  f.notes,
  f.excluded,
  f.plaid_id,
  f.entry_locked_attributes
FROM filtered f
JOIN inserted_transactions it ON TRUE;
