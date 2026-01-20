import 'package:fairshare/model/expense.dart';
import 'package:fairshare/model/expense_split.dart';
import 'package:fairshare/model/group.dart';
import 'package:fairshare/model/group_member.dart';

class ExpenseWithSplits {
  final Expense expense;
  final List<ExpenseSplit> splits;
  final String? payerName;

  ExpenseWithSplits({
    required this.expense,
    required this.splits,
    this.payerName,
  });

  double get totalSplitAmount =>
      splits.fold(0.0, (sum, split) => sum + split.amount);
  bool get allSplitsSettled => splits.every((split) => split.isSettled);
  int get settledCount => splits.where((split) => split.isSettled).length;
}

class GroupWithMembers {
  final Group group;
  final List<GroupMember> members;
  final int memberCount;

  GroupWithMembers({required this.group, required this.members})
    : memberCount = members.length;

  List<GroupMember> get admins =>
      members.where((member) => member.isAdmin).toList();

  List<GroupMember> get regularMembers =>
      members.where((member) => !member.isAdmin).toList();

  bool isUserAdmin(String userId) =>
      members.any((member) => member.userId == userId && member.isAdmin);
}
