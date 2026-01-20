class Expense {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String currency;
  final String categoryId;
  final String paidBy;
  final String? createdBy; // Who created this expense (may differ from paidBy)
  final DateTime expenseDate;
  final String splitType;
  final String? notes;
  final String? receiptUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional: associated category object (if joined)
  // final ExpenseCategory? category;

  Expense({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.currency,
    required this.categoryId,
    required this.paidBy,
    this.createdBy, // Optional - set by database trigger
    required this.expenseDate,
    required this.splitType,
    this.notes,
    this.receiptUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      groupId: json['group_id'],
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'Rs',
      categoryId: json['category_id'],
      paidBy: json['paid_by'],
      createdBy: json['created_by'], // Parse from database
      expenseDate: DateTime.parse(json['expense_date']),
      splitType: json['split_type'],
      notes: json['notes'],
      receiptUrl: json['receipt_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'description': description,
      'amount': amount,
      'currency': currency,
      'category_id': categoryId,
      'paid_by': paidBy,
      // Do NOT include created_by - database trigger handles it
      'expense_date': expenseDate.toIso8601String(),
      'split_type': splitType,
      'notes': notes,
      'receipt_url': receiptUrl,
    };
  }
}
