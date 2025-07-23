WITH split_base AS (
  SELECT
    e.id AS entry_id,
    t.id AS transaction_id,
    e.account_id,
    e.amount,
    e.currency,
    e.date,
    regexp_matches(e.name, '^(\d{1,2})/(\d{1,2}) (.+)$') AS parts,
    e.name,
    t.category_id,
    t.merchant_id,
    t.locked_attributes,
    t.kind,
    e.notes,
    e.excluded,
    e.plaid_id,
    e.locked_attributes AS entry_locked_attributes
  FROM entries e
  JOIN transactions t ON t.id = e.entryable_id AND e.entryable_type = 'Transaction'
  JOIN taggings tg ON tg.taggable_id = t.id AND tg.taggable_type = 'Transaction'
  WHERE tg.tag_id = '12e485ef-49d7-423e-a315-609d16684c31'
),
parsed AS (
  SELECT *,
         (parts[1])::int AS part,
         (parts[2])::int AS total_parts,
         parts[3] AS base_name
  FROM split_base
  WHERE parts IS NOT NULL
),
grouped AS (
  SELECT
    account_id,
    amount,
    currency,
    base_name,
    total_parts,
    MAX(part) AS max_existing_part,
    MIN(date) AS base_date,
    category_id,
    merchant_id,
    locked_attributes,
    kind,
    notes,
    excluded,
    plaid_id,
    entry_locked_attributes
  FROM parsed
  GROUP BY
    account_id, amount, currency, base_name, total_parts,
    category_id, merchant_id, locked_attributes, kind,
    notes, excluded, plaid_id, entry_locked_attributes
),
missing_parts AS (
  SELECT
    g.*,
    gs.n AS part_number,
    (g.base_date + (gs.n - 1) * INTERVAL '1 month')::date AS new_date,
    format('%s/%s %s', gs.n, g.total_parts, g.base_name) AS new_name
  FROM grouped g
  JOIN generate_series(1, 99) gs(n)
    ON gs.n <= g.total_parts AND gs.n > g.max_existing_part
),
filtered AS (
  SELECT mp.*
  FROM missing_parts mp
  LEFT JOIN entries e ON
    e.account_id = mp.account_id AND
    e.amount = mp.amount AND
    e.date = mp.new_date AND
    e.name = mp.new_name AND
    e.entryable_type = 'Transaction'
  WHERE e.id IS NULL
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
    account_id,
    amount,
    currency,
    date,
    name,
    notes,
    excluded,
    plaid_id,
    locked_attributes,
    entryable_id,
    entryable_type,
    created_at,
    updated_at
)
SELECT
    account_id,
    amount,
    currency,
    new_date,
    new_name,
    notes,
    excluded,
    plaid_id,
    entry_locked_attributes,
    (SELECT id FROM transactions t
     WHERE t.category_id = filtered.category_id
       AND t.merchant_id IS NOT DISTINCT FROM filtered.merchant_id
       AND t.kind = filtered.kind
       AND t.locked_attributes = filtered.locked_attributes
     ORDER BY t.created_at DESC
     LIMIT 1),
    'Transaction',
    now(),
    now()
FROM filtered
WHERE NOT EXISTS (
    SELECT 1 FROM entries e
    WHERE e.account_id = filtered.account_id
      AND e.amount = filtered.amount
      AND e.date = filtered.new_date
      AND e.name = filtered.new_name
      AND e.entryable_type = 'Transaction'
);
