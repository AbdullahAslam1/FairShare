class ExpenseSplit {
  final String? id; // Nullable for creation
  final String expenseId; // Can be empty during creation flow
  final String userId;
  final double amount;
  final double? percentage;
  final int? shares;
  final bool isSettled;

  ExpenseSplit({
    this.id,
    required this.expenseId,
    required this.userId,
    required this.amount,
    this.percentage,
    this.shares,
    this.isSettled = false,
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      id: json['id'],
      expenseId: json['expense_id'],
      userId: json['user_id'],
      amount: (json['amount'] as num).toDouble(),
      percentage: json['percentage'] != null ? (json['percentage'] as num).toDouble() : null,
      shares: json['shares'],
      isSettled: json['is_settled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'expense_id': expenseId,
      'user_id': userId,
      'amount': amount,
      'is_settled': isSettled,
    };
    if (percentage != null) data['percentage'] = percentage;
    if (shares != null) data['shares'] = shares;
    return data;
  }
}
