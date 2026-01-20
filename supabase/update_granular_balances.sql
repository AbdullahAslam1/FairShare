-- ============================================
-- Update Balance Calculation for Granular Splits
-- ============================================

CREATE OR REPLACE FUNCTION calculate_group_balances(p_group_id UUID)
RETURNS TABLE (
  user_id UUID,
  balance NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH 
  -- 1. Get detailed splits information joined with expenses
  -- We rely purely on UNSETTLED splits to determine debt.
  active_splits AS (
    SELECT 
      e.paid_by,
      es.user_id as member_id,
      es.amount
    FROM expense_splits es
    JOIN expenses e ON es.expense_id = e.id
    WHERE e.group_id = p_group_id
    AND es.is_settled = false -- KEY CHANGE: Only count unsettled splits
    -- We do NOT filter by e.status != 'cleared' because e.status should reflect the aggregate of splits.
    -- Even if e.status is 'pending', if a split is 'settled', it shouldn't count.
  ),

  -- 2. Calculate Credits (Money I paid for others that is not yet settled)
  -- Note: This includes money I paid for myself (if unsettled), which cancels out with Debits.
  credits AS (
    SELECT 
      paid_by as uid,
      SUM(amount) as total_credit
    FROM active_splits
    GROUP BY paid_by
  ),

  -- 3. Calculate Debits (Money I owe that is not yet settled)
  debits AS (
    SELECT 
      member_id as uid,
      SUM(amount) as total_debit
    FROM active_splits
    GROUP BY member_id
  ),

  -- 4. Get all users involved
  users AS (
    SELECT DISTINCT uid FROM credits
    UNION
    SELECT DISTINCT uid FROM debits
  )

  SELECT 
    u.uid as user_id,
    COALESCE(c.total_credit, 0) - COALESCE(d.total_debit, 0) as balance
  FROM users u
  LEFT JOIN credits c ON u.uid = c.uid
  LEFT JOIN debits d ON u.uid = d.uid;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions (redundant but safe)
GRANT EXECUTE ON FUNCTION calculate_group_balances(UUID) TO authenticated;
