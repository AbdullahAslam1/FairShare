-- ============================================
-- Check Deletion Eligibility Function
-- Determines if a group can be deleted
-- Checks:
-- 1. Unsettled balances in the entire group.
--    If ANY member has a balance > 1.0, deletion is blocked.
-- ============================================

CREATE OR REPLACE FUNCTION check_deletion_eligibility(p_group_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_unsettled_count INTEGER;
  v_total_unsettled NUMERIC;
BEGIN
  -- Check for any member with non-zero balance
  SELECT 
    COUNT(*),
    SUM(ABS(balance))
  INTO v_unsettled_count, v_total_unsettled
  FROM calculate_group_balances(p_group_id)
  WHERE ABS(balance) > 1.0; -- Threshold for rounding

  IF v_unsettled_count > 0 THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'reason', 'Cannot delete group. There are unsettled expenses remaining.',
      'unsettled_amount', v_total_unsettled,
      'code', 'UNSETTLED_DEBTS'
    );
  END IF;

  -- Allowed
  RETURN jsonb_build_object(
    'allowed', true
  );
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION check_deletion_eligibility(UUID) TO authenticated;
