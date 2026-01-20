class UserBudget {
  final String id;
  final String userId;
  final double weeklyLimit;
  final double monthlyLimit;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserBudget({
    required this.id,
    required this.userId,
    required this.weeklyLimit,
    required this.monthlyLimit,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserBudget.fromJson(Map<String, dynamic> json) {
    return UserBudget(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      weeklyLimit: (json['weekly_limit'] as num?)?.toDouble() ?? 0.0,
      monthlyLimit: (json['monthly_limit'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'weekly_limit': weeklyLimit,
      'monthly_limit': monthlyLimit,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserBudget copyWith({
    String? id,
    String? userId,
    double? weeklyLimit,
    double? monthlyLimit,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserBudget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weeklyLimit: weeklyLimit ?? this.weeklyLimit,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
