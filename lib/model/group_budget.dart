class GroupBudget {
  final String id;
  final String groupId;
  final double weeklyLimit;
  final double monthlyLimit;
  final String currency;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupBudget({
    required this.id,
    required this.groupId,
    this.weeklyLimit = 0.0,
    this.monthlyLimit = 0.0,
    this.currency = 'USD',
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupBudget.fromJson(Map<String, dynamic> json) {
    return GroupBudget(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      weeklyLimit: (json['weekly_limit'] as num?)?.toDouble() ?? 0.0,
      monthlyLimit: (json['monthly_limit'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'weekly_limit': weeklyLimit,
      'monthly_limit': monthlyLimit,
      'currency': currency,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GroupBudget copyWith({
    String? id,
    String? groupId,
    double? weeklyLimit,
    double? monthlyLimit,
    String? currency,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupBudget(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      weeklyLimit: weeklyLimit ?? this.weeklyLimit,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currency: currency ?? this.currency,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
