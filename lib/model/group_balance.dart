class GroupBalance {
  final String userId;
  final String userName;
  final double balance;

  GroupBalance({
    required this.userId,
    required this.userName,
    required this.balance,
  });

  factory GroupBalance.fromJson(Map<String, dynamic> json) {
    return GroupBalance(
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      balance: (json['balance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'user_name': userName, 'balance': balance};
  }

  bool get owesBalance => balance < 0;
  bool get owedBalance => balance > 0;
  bool get isSettled => balance == 0;

  double get absoluteBalance => balance.abs();
}
