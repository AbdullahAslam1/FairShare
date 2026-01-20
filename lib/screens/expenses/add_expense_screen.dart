import 'package:fairshare/core/theme/app_theme.dart';
import 'package:fairshare/model/expense.dart';
import 'package:fairshare/model/expense_category.dart';
import 'package:fairshare/model/expense_split.dart';
import 'package:fairshare/riverpod/user_budget_provider.dart';
import 'package:fairshare/screens/expenses/expense_success_screen.dart';
import 'package:fairshare/screens/expenses/split_expense_screen.dart';
import 'package:fairshare/services/expense_service.dart';
import 'package:fairshare/services/group_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;
  final Map<String, dynamic>? expenseToEdit;

  const AddExpenseScreen({
    super.key,
    required this.groupId,
    this.expenseToEdit,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final GroupService _groupService = GroupService();
  final _supabase = Supabase.instance.client;

  final _amountController = TextEditingController();
  final _descriptionController =
      TextEditingController(); // This is expense name/title
  final _notesController = TextEditingController(); // Optional description

  DateTime _selectedDate = DateTime.now();
  ExpenseCategory? _selectedCategory;
  List<ExpenseCategory> _categories = [];

  // Members & Split State
  List<Map<String, dynamic>> _groupMembers = [];
  String _payerId = ''; // User ID who paid

  // CHANGED: 'EQUAL' -> 'equal' to match database constraint
  String _splitType = 'equal'; // equal, custom, percentage, shares

  // Advanced Split Configuration Storage
  Map<String, double> _customAmounts = {};
  Map<String, double> _customPercentages = {};
  Map<String, int> _customShares = {};

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _payerId = _supabase.auth.currentUser!.id;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final categories = await _expenseService.getCategories();
      final members = await _groupService.getGroupMembers(widget.groupId);

      if (mounted) {
        setState(() {
          _categories = categories;
          _groupMembers = members;

          // Default category
          if (_categories.isNotEmpty) {
            _selectedCategory = _categories.firstWhere(
              (c) => c.name == 'General',
              orElse: () => _categories.first,
            );
          }

          // IF EDITING: Pre-fill data
          if (widget.expenseToEdit != null) {
            _prefillEditData();
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _prefillEditData() {
    final e = widget.expenseToEdit!;
    
    // 1. Text Fields
    _amountController.text = (e['amount'] as num).toString(); // Keep it simple without decimals if integer? No, double is fine.
    _descriptionController.text = e['description'] as String;
    _notesController.text = e['notes'] as String? ?? '';
    
    // 2. Date
    if (e['expense_date'] != null) {
      _selectedDate = DateTime.parse(e['expense_date']).toLocal();
    }

    // 3. Category
    if (e['category_id'] != null) {
      try {
        _selectedCategory = _categories.firstWhere((c) => c.id == e['category_id']);
      } catch (_) {}
    }

    // 4. Payer
    if (e['paid_by'] != null) {
      // paid_by could be an object or ID depending on query. 
      // In group_detail we saw: profiles:paid_by(*), so e['paid_by'] might be null if not flattened?
      // Wait, in group_detail: payer = expenseData['profiles']
      // BUT raw DB column is paid_by. 
      // Let's check the map.
      // Usually Supabase returns the foreign key column too if simple select, 
      // but if we joined receiving 'profiles', we might not have 'paid_by' key directly if not requested?
      // ExpenseService getGroupExpensesWithSplits selects: '*, ...' so 'paid_by' (the ID) should be there.
      
      _payerId = e['paid_by'] is String ? e['paid_by'] : (e['profiles']?['id'] ?? _payerId);
    }

    // 5. Split Type
    _splitType = e['split_type'] ?? 'equal';

    // 6. Custom Split Data
    // We need to verify if we have splits in expenseToEdit
    final splits = e['splits'] as List? ?? [];
    if (splits.isNotEmpty) {
      for (var s in splits) {
        final uid = s['user_id'];
        _customAmounts[uid] = (s['amount'] as num).toDouble();
        _customPercentages[uid] = (s['percentage'] as num).toDouble();
        _customShares[uid] = (s['shares'] as num).toInt();
      }
    }
  }

  void _presentDatePicking() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: AppTheme.lightTheme.copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.teal600),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _onChangeSplitType(String? newValue) async {
    if (newValue == null) return;

    // CHANGED: Check for 'equal' instead of 'EQUAL'
    if (newValue == 'equal') {
      setState(() => _splitType = 'equal');
    } else {
      // Navigate to configuration screen
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid amount first")),
        );
        return;
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SplitConfigurationScreen(
            amount: amount,
            members: _groupMembers,
            initialSplitType: newValue,
          ),
        ),
      );

      if (result != null && result is Map) {
        setState(() {
          _splitType = result['splitType'];
          _customAmounts = result['amounts'] ?? {};
          _customPercentages = result['percentages'] ?? {};
          _customShares = result['shares'] ?? {};
        });
      }
    }
  }

  Future<void> _onSubmit() async {
    if (_isSubmitting) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a description")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Calculate Split Objects
      List<ExpenseSplit> splits = [];
      final count = _groupMembers.length;

      // CHANGED: All comparison values changed to lowercase
      if (_splitType == 'equal') {
        // Was: 'EQUAL'
        final share = amount / count;
        for (var m in _groupMembers) {
          splits.add(
            ExpenseSplit(
              userId: m['user_id'],
              amount: share,
              percentage: 100 / count,
              shares: 1,
              expenseId: '',
            ),
          );
        }
      } else if (_splitType == 'custom') {
        // Was: 'EXACT_AMOUNT', now matches DB 'custom'
        for (var m in _groupMembers) {
          final uid = m['user_id'];
          final amt = _customAmounts[uid] ?? 0;
          splits.add(
            ExpenseSplit(
              userId: uid,
              amount: amt,
              percentage: (amt / amount) * 100,
              expenseId: '',
            ),
          );
        }
      } else if (_splitType == 'percentage') {
        // Was: 'PERCENTAGE'
        for (var m in _groupMembers) {
          final uid = m['user_id'];
          final pct = _customPercentages[uid] ?? 0;
          splits.add(
            ExpenseSplit(
              userId: uid,
              amount: (amount * pct) / 100,
              percentage: pct,
              expenseId: '',
            ),
          );
        }
      } else if (_splitType == 'shares') {
        // Was: 'SHARES'
        final totalShares = _customShares.values.fold(
          0,
          (sum, val) => sum + val,
        );
        for (var m in _groupMembers) {
          final uid = m['user_id'];
          final shares = _customShares[uid] ?? 0;
          splits.add(
            ExpenseSplit(
              userId: uid,
              amount: totalShares > 0 ? (amount * shares) / totalShares : 0,
              shares: shares,
              expenseId: '',
            ),
          );
        }
      }

      // 2. Create Expense Object
      final newExpense = Expense(
        groupId: widget.groupId,
        description: _descriptionController.text,
        amount: amount,
        currency: 'Rs',
        categoryId: _selectedCategory!.id,
        paidBy: _payerId,
        expenseDate: _selectedDate,
        splitType: _splitType,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        // If editing, preserve ID and created_at
        id: widget.expenseToEdit?['id'] ?? '',
        createdAt: widget.expenseToEdit != null 
            ? DateTime.parse(widget.expenseToEdit!['created_at']) 
            : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 3. Submit
      if (widget.expenseToEdit != null) {
        await _expenseService.updateExpenseWithSplits(
          expense: newExpense,
          splits: splits,
        );
         if (mounted) {
          // ADDED: Refresh budget data after expense update
          ref.read(userBudgetProvider.notifier).onExpenseChanged();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Expense updated successfully")),
          );
          Navigator.pop(context, true); // Return true to indicate update
        }

      } else {
        await _expenseService.createExpense(expense: newExpense, splits: splits);
        if (mounted) {
          // ADDED: Refresh budget data after expense creation
          ref.read(userBudgetProvider.notifier).onExpenseChanged();
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ExpenseSuccessScreen()),
          );
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showPayerSelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Who paid?",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _groupMembers.length,
                  itemBuilder: (context, index) {
                    final member = _groupMembers[index];
                    final profile = member['profiles'] ?? {};
                    final name = profile['full_name'] ?? 'Unknown';
                    final uid = member['user_id'];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.teal100,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: GoogleFonts.oi(color: AppColors.teal800),
                        ),
                      ),
                      title: Text(name),
                      trailing: _payerId == uid
                          ? const Icon(Icons.check, color: AppColors.teal600)
                          : null,
                      onTap: () {
                        setState(() => _payerId = uid);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine Payer Name
    String payerName = "You";
    if (_payerId != _supabase.auth.currentUser?.id) {
      final payer = _groupMembers.firstWhere(
        (m) => m['user_id'] == _payerId,
        orElse: () => {},
      );
      payerName = payer['profiles']?['full_name'] ?? 'Unknown';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.expenseToEdit != null ? "Edit Expense" : "Add Expense",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _onSubmit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    "Save",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.teal600,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal600),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Input
                    Center(
                      child: IntrinsicWidth(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppColors.teal600,
                          ),
                          decoration: InputDecoration(
                            prefixText: 'Rs ',
                            prefixStyle: GoogleFonts.outfit(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppColors.teal600,
                            ),
                            hintText: '0',
                            hintStyle: GoogleFonts.outfit(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppColors.neutral300,
                            ),
                            border: InputBorder.none,
                          ),
                          autofocus: true,
                          onChanged: (val) {
                            // If non-equal split is active, we might warn user that splits need update
                            // But for now we just let them proceed
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Name / Description
                    _buildLabel("Expense Name"),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _inputDecoration(
                        "e.g. Dinner, Taxi",
                        Icons.title_rounded,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Paid By & Split Type Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Paid By"),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _showPayerSelection,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.neutral50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.neutral200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          payerName,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Split Type"),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.neutral50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.neutral200,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _splitType,
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: AppColors.textSecondary,
                                    ),
                                    // CHANGED: All dropdown values to lowercase
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'equal', // Was: 'EQUAL'
                                        child: Text("Equally"),
                                      ),
                                      DropdownMenuItem(
                                        value:
                                            'custom', // Was: 'EXACT_AMOUNT', changed to match DB
                                        child: Text("Exact Amount"),
                                      ),
                                      DropdownMenuItem(
                                        value:
                                            'percentage', // Was: 'PERCENTAGE'
                                        child: Text("Percentage"),
                                      ),
                                      DropdownMenuItem(
                                        value: 'shares', // Was: 'SHARES'
                                        child: Text("By Shares"),
                                      ),
                                    ],
                                    onChanged: _onChangeSplitType,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Date & Category
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Date"),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _presentDatePicking,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.neutral50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.neutral200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 18,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat(
                                          'MMM dd',
                                        ).format(_selectedDate),
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Category"),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.neutral50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.neutral200,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<ExpenseCategory>(
                                    value: _selectedCategory,
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: AppColors.textSecondary,
                                    ),
                                    items: [
                                      ..._categories.map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Row(
                                            children: [
                                              Text(c.icon), // Emoji
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  c.name,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: null, // Special value for "Add"
                                        child: Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: AppColors.teal50,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              padding: const EdgeInsets.all(2),
                                              child: const Icon(
                                                Icons.add,
                                                size: 16,
                                                color: AppColors.teal600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Create New...",
                                              style: GoogleFonts.inter(
                                                color: AppColors.teal600,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val == null) {
                                        _showCreateCategoryDialog();
                                      } else {
                                        setState(() => _selectedCategory = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Optional Note
                    _buildLabel("Description (Optional)"),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: _inputDecoration(
                        "Add more details...",
                        Icons.notes_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: AppColors.textTertiary),
      filled: true,
      fillColor: AppColors.neutral50,
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.neutral200),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  // --- Create Category Dialog ---
  void _showCreateCategoryDialog() {
    final nameCtrl = TextEditingController();
    final emojiCtrl = TextEditingController();
    String selectedColor = '#FF6B6B'; // Default red
    
    // Preset colors
    final colors = [
      '#FF6B6B', // Red
      '#4ECDC4', // Teal
      '#F38181', // Pink
      '#AA96DA', // Purple
      '#FFD93D', // Yellow
      '#6BCB77', // Green
      '#4D96FF', // Blue
      '#9E9E9E', // Grey
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              "New Category",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   // Emoji Input
                   TextField(
                     controller: emojiCtrl,
                     maxLength: 10, // Increased to support complex emojis (flags, families)
                     textAlign: TextAlign.center,
                     style: const TextStyle(fontSize: 32),
                     decoration: const InputDecoration(
                       hintText: "🍔",
                       counterText: "",
                       border: InputBorder.none,
                     ),
                   ),
                   const SizedBox(height: 8),
                   
                   // Name Input
                   TextField(
                     controller: nameCtrl,
                     decoration: _dialogInputDecoration("Category Name (e.g. Sushi)"),
                   ),
                   const SizedBox(height: 16),
                   
                   // Color Picker
                   Wrap(
                     spacing: 8,
                     runSpacing: 8,
                     children: colors.map((color) {
                       final isSelected = selectedColor == color;
                       return GestureDetector(
                         onTap: () => setStateDialog(() => selectedColor = color),
                         child: Container(
                           width: 32,
                           height: 32,
                           decoration: BoxDecoration(
                             color: Color(int.parse(color.replaceAll('#', '0xff'))),
                             shape: BoxShape.circle,
                             border: isSelected 
                               ? Border.all(color: AppColors.textPrimary, width: 2)
                               : null,
                           ),
                           child: isSelected 
                             ? const Icon(Icons.check, size: 16, color: Colors.white)
                             : null,
                         ),
                       );
                     }).toList(),
                   ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  if (emojiCtrl.text.isEmpty || nameCtrl.text.isEmpty) {
                    return;
                  }
                  
                  try {
                    // Show loading if needed, or just await
                    final newCategory = await _expenseService.createCategory(
                      name: nameCtrl.text,
                      icon: emojiCtrl.text,
                      color: selectedColor,
                    );
                    
                    if (mounted) {
                      Navigator.pop(context);
                      // Update main state
                      setState(() {
                         _categories.add(newCategory);
                         // Sort again? or just add
                         _categories.sort((a,b) => a.name.compareTo(b.name));
                         _selectedCategory = newCategory;
                      });
                    }
                  } catch (e) {
                    // Handle error
                    debugPrint('Err: $e');
                  }
                },
                child: const Text("Create"),
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _dialogInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.neutral50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
