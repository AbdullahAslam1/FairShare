class ExpenseItem {
  final String id;
  final String description;
  final double amount;
  final String paidBy;
  final DateTime date;
  final String category;
  final double yourShare;

  ExpenseItem({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.date,
    required this.category,
    required this.yourShare,
  });
}
