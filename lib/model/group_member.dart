enum MemberRole {
  admin,
  member;

  static MemberRole fromString(String role) {
    return MemberRole.values.firstWhere(
      (e) => e.name == role.toLowerCase(),
      orElse: () => MemberRole.member,
    );
  }
}

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final MemberRole role;
  final DateTime joinedAt;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      role: MemberRole.fromString(json['role'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'role': role.name,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  bool get isAdmin => role == MemberRole.admin;

  GroupMember copyWith({
    String? id,
    String? groupId,
    String? userId,
    MemberRole? role,
    DateTime? joinedAt,
  }) {
    return GroupMember(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
