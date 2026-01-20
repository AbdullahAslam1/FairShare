-- ============================================
-- 1. Add Status Column to Expenses
-- ============================================

-- Add status column with check constraint
ALTER TABLE expenses 
ADD COLUMN IF NOT EXISTS status TEXT CHECK (status IN ('pending', 'cleared')) DEFAULT 'pending';

-- Add cleared_at timestamp
ALTER TABLE expenses 
ADD COLUMN IF NOT EXISTS cleared_at TIMESTAMPTZ;

-- ============================================
-- 2. Update Balance Calculation
-- MUST EXCLUDE 'cleared' expenses from debt calculations
-- ============================================

CREATE OR REPLACE FUNCTION calculate_group_balances(p_group_id UUID)
RETURNS TABLE (
  user_id UUID,
  balance NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH 
  -- 1. Get money spent by each user (Credits)
  -- EXCLUDING CLEARED expenses
  spending AS (
    SELECT 
      e.paid_by as uid,
      SUM(e.amount) as amount_spent
    FROM expenses e
    WHERE e.group_id = p_group_id
    AND e.status != 'cleared' -- Logic Update
    GROUP BY e.paid_by
  ),
  
  -- 2. Get fair share for each user (Debits)
  -- EXCLUDING CLEARED expenses
  shares AS (
    SELECT 
      es.user_id as uid,
      SUM(es.amount) as share_amount
    FROM expense_splits es
    JOIN expenses e ON es.expense_id = e.id
    WHERE e.group_id = p_group_id
    AND e.status != 'cleared' -- Logic Update
    GROUP BY es.user_id
  ),
  
  -- 3. Get all relevant users
  users AS (
    SELECT DISTINCT uid FROM spending
    UNION
    SELECT DISTINCT uid FROM shares
  )
  
  SELECT 
    u.uid as user_id,
    COALESCE(s.amount_spent, 0) - COALESCE(sh.share_amount, 0) as balance
  FROM users u
  LEFT JOIN spending s ON u.uid = s.uid
  LEFT JOIN shares sh ON u.uid = sh.uid;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION calculate_group_balances(UUID) TO authenticated;
