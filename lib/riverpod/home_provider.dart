import 'package:fairshare/model/expense_item.dart';
import 'package:fairshare/model/group_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Navigation state provider
final navigationProvider = StateProvider<int>((ref) => 0);

// User balance providers
final userBalanceProvider = StateProvider<double>((ref) => -245.50);
final totalOwedProvider = StateProvider<double>((ref) => 320.00);
final totalOweProvider = StateProvider<double>((ref) => 565.50);

// Recent expenses provider
final recentExpensesProvider = Provider<List<ExpenseItem>>((ref) {
  return [
    ExpenseItem(
      id: '1',
      description: 'Dinner at Italian Restaurant',
      amount: 120.00,
      paidBy: 'Sarah',
      date: DateTime.now().subtract(Duration(hours: 5)),
      category: 'Food',
      yourShare: 40.00,
    ),
    ExpenseItem(
      id: '2',
      description: 'Uber to Airport',
      amount: 45.50,
      paidBy: 'You',
      date: DateTime.now().subtract(Duration(days: 1)),
      category: 'Transport',
      yourShare: 15.17,
    ),
    ExpenseItem(
      id: '3',
      description: 'Movie Tickets',
      amount: 60.00,
      paidBy: 'Mike',
      date: DateTime.now().subtract(Duration(days: 2)),
      category: 'Entertainment',
      yourShare: 20.00,
    ),
  ];
});

// Active groups provider
final activeGroupsProvider = Provider<List<GroupItem>>((ref) {
  return [
    GroupItem(
      id: '1',
      name: 'Weekend Trip',
      memberCount: 5,
      balance: -85.50,
      category: 'Travel',
    ),
    GroupItem(
      id: '2',
      name: 'Roommates',
      memberCount: 3,
      balance: 120.00,
      category: 'Home',
    ),
    GroupItem(
      id: '3',
      name: 'Office Lunch',
      memberCount: 8,
      balance: -280.00,
      category: 'Work',
    ),
  ];
});
