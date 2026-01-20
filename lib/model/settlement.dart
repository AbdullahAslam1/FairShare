class Settlement {
  final String id;
  final String groupId;
  final String payerId;
  final String payeeId;
  final double amount;
  final String currency;
  final DateTime settlementDate;
  final String? notes;
  final String? paymentMethod;
  final DateTime createdAt;

  Settlement({
    required this.id,
    required this.groupId,
    required this.payerId,
    required this.payeeId,
    required this.amount,
    this.currency = 'Rs',
    required this.settlementDate,
    this.notes,
    this.paymentMethod,
    required this.createdAt,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      payerId: json['payer_id'] as String,
      payeeId: json['payee_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'Rs',
      settlementDate: DateTime.parse(json['settlement_date'] as String),
      notes: json['notes'] as String?,
      paymentMethod: json['payment_method'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'payer_id': payerId,
      'payee_id': payeeId,
      'amount': amount,
      'currency': currency,
      'settlement_date': settlementDate.toIso8601String(),
      'notes': notes,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Settlement copyWith({
    String? id,
    String? groupId,
    String? payerId,
    String? payeeId,
    double? amount,
    String? currency,
    DateTime? settlementDate,
    String? notes,
    String? paymentMethod,
    DateTime? createdAt,
  }) {
    return Settlement(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      payerId: payerId ?? this.payerId,
      payeeId: payeeId ?? this.payeeId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      settlementDate: settlementDate ?? this.settlementDate,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
