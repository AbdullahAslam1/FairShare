class ExpenseCategory {
  final String id;
  final String name;
  final String icon;
  final String color; // Hex string, e.g. "#FF0000"
  final String? createdBy; // NULL for system categories, UserID for custom
  final bool isDefault;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.createdBy,
    required this.isDefault,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      color: json['color'],
      createdBy: json['created_by'],
      isDefault: json['is_default'] ?? false,
    );
  }
}
