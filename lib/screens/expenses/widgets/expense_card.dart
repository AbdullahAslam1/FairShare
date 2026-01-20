import 'package:fairshare/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpenseCard extends StatefulWidget {
  final Map<String, dynamic> expenseData;
  final Function(String expenseId) onMarkAsCleared;
  final String currentUserId;

  final dynamic isExpanded;

  final dynamic onToggleExpand;

  final Function(String splitId, bool isSettled, String expenseId)?
  onToggleSplit;
  final Function(String expenseId, String description) onDelete;
  final Function(Map<String, dynamic> expenseData) onEdit;

  ExpenseCard({
    super.key,
    required this.expenseData,
    required this.onDelete,
    required this.onEdit,
    required this.onMarkAsCleared,
    required this.currentUserId,
    this.isExpanded = false,
    this.onToggleSplit,
    required this.onToggleExpand,
  });

  @override
  State<ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends State<ExpenseCard> {
  @override
  Widget build(BuildContext context) {
    final expenseId = widget.expenseData['id'] as String;
    final description = widget.expenseData['description'] as String;
    final amount = (widget.expenseData['amount'] as num).toDouble();
    final category =
        widget.expenseData['expense_categories'] as Map<String, dynamic>?;
    final payer = widget.expenseData['profiles'] as Map<String, dynamic>?;
    final splits = widget.expenseData['splits'] as List? ?? [];
    final createdBy = widget.expenseData['created_by'] as String?;
    final paidBy = widget.expenseData['paid_by'] as String?;
    final status = widget.expenseData['status'] as String? ?? 'pending';
    final isCleared = status == 'cleared';

    final categoryIcon = category?['icon'] as String? ?? '💰';
    final payerName = payer?['full_name'] as String? ?? 'Unknown';

    final isPayer = paidBy == widget.currentUserId;
    final canModify =
        !isCleared && (createdBy != null && createdBy == widget.currentUserId);
    final canClear = !isCleared && isPayer;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isExpanded
              ? AppColors.teal600.withOpacity(0.3)
              : AppColors.border,
          width: widget.isExpanded ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isExpanded
                ? AppColors.teal600.withOpacity(0.1)
                : Colors.black.withOpacity(0.04),
            blurRadius: widget.isExpanded ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onToggleExpand,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isCleared
                                ? AppColors.success500.withOpacity(0.1)
                                : AppColors.teal50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              categoryIcon,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        if (isCleared)
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: AppColors.success500,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  description,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppColors.textPrimary,
                                    decoration: isCleared
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCleared)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success500,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'CLEARED',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Paid by ',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                payerName,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.teal600,
                                ),
                              ),
                            ],
                          ),
                          if (isCleared &&
                              widget.expenseData['cleared_at'] != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 12,
                                  color: AppColors.success500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatClearedDate(
                                    widget.expenseData['cleared_at'],
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.success600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Rs ${amount.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isCleared
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                letterSpacing: -0.5,
                                decoration: isCleared
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (canModify || canClear)
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert_rounded,
                                  color: AppColors.textTertiary,
                                  size: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    widget.onDelete(expenseId, description);
                                  } else if (value == 'edit') {
                                    widget.onEdit(widget.expenseData);
                                  } else if (value == 'clear') {
                                    _confirmClear(context, expenseId);
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (canClear)
                                    PopupMenuItem(
                                      value: 'clear',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_outline_rounded,
                                            color: AppColors.success500,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Mark as Cleared',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: AppColors.success600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (canModify) ...[
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.edit_rounded,
                                            color: AppColors.teal600,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Edit',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.delete_rounded,
                                            color: AppColors.danger500,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Delete',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: AppColors.danger500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          widget.isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildSplitsSection(splits),
            crossFadeState: widget.isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, String expenseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success500,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Mark as Cleared?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This indicates that everyone has paid you back effectively settling this expense.',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning100),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.warning600,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.warning600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Confirm',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      widget.onMarkAsCleared(expenseId);
    }
  }

  Widget _buildSplitsSection(List splits) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            color: AppColors.border.withOpacity(0.5),
            margin: const EdgeInsets.only(bottom: 12),
          ),
          Text(
            'Split Details',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...splits
              .map(
                (split) => _buildSplitItem(
                  split,
                  widget.expenseData['paid_by'] == widget.currentUserId,
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildSplitItem(Map<String, dynamic> split, bool isPayer) {
    final amount = (split['amount'] as num).toDouble();
    final isSettled = split['is_settled'] as bool? ?? false;
    final splitId = split['id'] as String?;
    final expenseId = widget.expenseData['id'] as String;

    // Check if this split belongs to the payer (self-split) - usually auto-settled or ignored
    // But for now, we allow toggling any split if you are the payer (you mark who paid you back).
    final canToggle = isPayer && widget.onToggleSplit != null;

    final profile = split['profiles'] as Map<String, dynamic>?;
    final userName = profile?['full_name'] as String? ?? 'Unknown';
    final userEmail = profile?['email'] as String? ?? '';
    final avatarUrl = profile?['avatar_url'] as String?;

    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSettled
            ? AppColors.success500.withOpacity(0.05)
            : AppColors.warning500.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSettled
              ? AppColors.success500.withOpacity(0.2)
              : AppColors.warning500.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSettled
                    ? [AppColors.success500, AppColors.success600]
                    : [AppColors.warning500, AppColors.warning600],
              ),
              borderRadius: BorderRadius.circular(10),
              image: avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarUrl == null
                ? Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (userEmail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    userEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs ${amount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canToggle
                      ? () {
                          if (splitId != null) {
                            widget.onToggleSplit!(splitId, !isSettled, expenseId);
                          }
                        }
                      : null,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSettled
                          ? AppColors.success500
                          : AppColors.warning500,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canToggle) ...[
                          Icon(
                            isSettled ? Icons.check_box_outlined : Icons.check_box_outline_blank_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                        ] else
                          Row(
                            children: [
                              Icon(
                                isSettled ? Icons.check_circle : Icons.schedule,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                            ],
                          ),
                        Text(
                          isSettled ? 'Settled' : 'Pending',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatClearedDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr).toLocal();
    return 'Cleared on ${date.day}/${date.month} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
