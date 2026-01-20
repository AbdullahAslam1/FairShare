-- ============================================
-- Check Exit Eligibility Function
-- Determines if a user can leave a group
-- Checks:
-- 1. Unsettled balance (Must be near zero)
-- 2. Last Admin status (Cannot leave if they are the only admin)
-- ============================================

CREATE OR REPLACE FUNCTION check_exit_eligibility(p_group_id UUID, p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_balance NUMERIC;
  v_admin_count INTEGER;
  v_is_admin BOOLEAN;
BEGIN
  -- 1. Check Balance
  -- Get balance using the existing calculation function
  SELECT balance INTO v_balance
  FROM calculate_group_balances(p_group_id)
  WHERE user_id = p_user_id;

  v_balance := COALESCE(v_balance, 0);

  -- Use a small threshold (e.g., 1.0) to account for rounding differences
  IF ABS(v_balance) > 1.0 THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'reason', CASE 
                  WHEN v_balance > 0 THEN 'You are owed money. Settle up before leaving.'
                  ELSE 'You owe money. Settle up before leaving.'
                END,
      'balance', v_balance,
      'code', 'UNSETTLED_BALANCE'
    );
  END IF;

  -- 2. Check Admin Status
  SELECT 
    COUNT(*) FILTER (WHERE role = 'admin'),
    BOOL_OR(user_id = p_user_id AND role = 'admin')
  INTO v_admin_count, v_is_admin
  FROM group_members
  WHERE group_id = p_group_id;

  IF v_is_admin AND v_admin_count <= 1 THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'reason', 'You are the last admin. Promote another member to admin before leaving.',
      'code', 'LAST_ADMIN'
    );
  END IF;

  -- 3. Allowed
  RETURN jsonb_build_object(
    'allowed', true
  );
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION check_exit_eligibility(UUID, UUID) TO authenticated;
