import 'package:fairshare/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplitConfigurationScreen extends StatefulWidget {
  final double amount;
  final List<Map<String, dynamic>> members;
  // CHANGED: Comment updated to reflect lowercase values
  final String initialSplitType; // 'equal', 'custom', 'percentage', 'shares'

  const SplitConfigurationScreen({
    super.key,
    required this.amount,
    required this.members,
    required this.initialSplitType,
  });

  @override
  State<SplitConfigurationScreen> createState() =>
      _SplitConfigurationScreenState();
}

class _SplitConfigurationScreenState extends State<SplitConfigurationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Split Data
  // CHANGED: Comment updated - 'custom' instead of 'EXACT_AMOUNT'
  Map<String, double> _userAmounts = {}; // For 'custom'
  Map<String, double> _userPercentages = {}; // For 'percentage'
  Map<String, int> _userShares = {}; // For 'shares'

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;

    // CHANGED: All switch cases changed to lowercase to match database values
    switch (widget.initialSplitType) {
      case 'custom': // Was: 'EXACT_AMOUNT'
        initialIndex = 1;
        break;
      case 'percentage': // Was: 'PERCENTAGE'
        initialIndex = 2;
        break;
      case 'shares': // Was: 'SHARES'
        initialIndex = 3;
        break;
      default: // 'equal'
        initialIndex = 0;
    }

    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: initialIndex,
    );

    // Initialize default values
    for (var m in widget.members) {
      final uid = m['user_id'] as String;
      _userShares[uid] = 1;
      _userPercentages[uid] = 0; // Will be calculated if switched
      _userAmounts[uid] = 0; // Will be calculated if switched
    }

    // Default distribution for Amount mode if entering it fresh
    _distributeEquallyToAmounts();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Reset or recalculate logic when switching tabs if needed
        if (_tabController.index == 1) _distributeEquallyToAmounts();
      }
    });
  }

  void _distributeEquallyToAmounts() {
    // Helper to set start values for amounts so user doesn't start at 0
    final count = widget.members.length;
    if (count == 0) return;
    final share = (widget.amount / count).floorToDouble();
    double remainder = widget.amount - (share * count);

    for (var i = 0; i < widget.members.length; i++) {
      final m = widget.members[i];
      double amount = share;
      if (i < remainder) {
        // Distribute remainder to first few
        amount += 1;
      }
      _userAmounts[m['user_id']] = amount;
    }
  }

  double get _totalAssignedAmount {
    return _userAmounts.values.fold(0.0, (sum, val) => sum + val);
  }

  double get _totalAssignedPercentage {
    return _userPercentages.values.fold(0.0, (sum, val) => sum + val);
  }

  // CHANGED: All return values changed to lowercase to match database constraint
  // Determine split type string based on tab index
  String get _currentSplitType {
    switch (_tabController.index) {
      case 0:
        return 'equal'; // Was: 'EQUAL'
      case 1:
        return 'custom'; // Was: 'EXACT_AMOUNT', changed to match DB
      case 2:
        return 'percentage'; // Was: 'PERCENTAGE'
      case 3:
        return 'shares'; // Was: 'SHARES'
      default:
        return 'equal'; // Was: 'EQUAL'
    }
  }

  void _onDone() {
    // CHANGED: All comparison values changed to lowercase
    // Validation
    if (_currentSplitType == 'custom') {
      // Was: 'EXACT_AMOUNT'
      final diff = (widget.amount - _totalAssignedAmount).abs();
      if (diff > 0.5) {
        // Integer tolerance
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Amounts must sum to Rs${widget.amount.toInt()}. Diff: Rs${diff.toInt()}",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else if (_currentSplitType == 'percentage') {
      // Was: 'PERCENTAGE'
      final total = _totalAssignedPercentage;
      if ((total - 100).abs() > 0.1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Percentages must sum to 100%. Current: ${total.toStringAsFixed(1)}%",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else if (_currentSplitType == 'shares') {
      // Was: 'SHARES'
      final totalShares = _userShares.values.fold(0, (sum, val) => sum + val);
      if (totalShares == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Total shares cannot be 0"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Return the configuration (now with lowercase values)
    Navigator.pop(context, {
      'splitType': _currentSplitType,
      'amounts': _userAmounts,
      'percentages': _userPercentages,
      'shares': _userShares,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Split Configuration",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.teal600,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.teal600,
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: "Equals"),
            Tab(text: "Amount"),
            Tab(text: "%"),
            Tab(text: "Shares"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Total Amount Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Total: ",
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Rs${widget.amount.toInt()}",
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.teal600,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEqualTab(),
                _buildAmountTab(),
                _buildPercentageTab(),
                _buildSharesTab(),
              ],
            ),
          ),

          // Done Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Done",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // TABS
  // ============================================

  Widget _buildEqualTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.members.length,
      itemBuilder: (context, index) {
        final member = widget.members[index];
        // Integer division display logic
        final share = (widget.amount / widget.members.length).floor();

        return _buildMemberRow(
          member,
          Text(
            "Rs$share",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );
      },
    );
  }

  Widget _buildAmountTab() {
    double remaining = widget.amount - _totalAssignedAmount;
    Color remainingColor = remaining.abs() < 0.5
        ? AppColors.teal600
        : Colors.red;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Remaining:",
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              Text(
                "Rs${remaining.toInt()}",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: remainingColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.members.length,
            itemBuilder: (context, index) {
              final member = widget.members[index];
              final uid = member['user_id'];
              return _buildMemberRow(
                member,
                SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: 'Rs ',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _userAmounts[uid] = double.tryParse(val) ?? 0.0;
                      });
                    },
                    controller:
                        TextEditingController(
                            text: (_userAmounts[uid] ?? 0).toInt().toString(),
                          )
                          ..selection = TextSelection.collapsed(
                            offset: (_userAmounts[uid] ?? 0)
                                .toInt()
                                .toString()
                                .length,
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPercentageTab() {
    double total = _totalAssignedPercentage;
    Color totalColor = (total - 100).abs() < 0.1
        ? AppColors.teal600
        : Colors.red;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total %:",
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              Text(
                "${total.toStringAsFixed(1)}%",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: totalColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.members.length,
            itemBuilder: (context, index) {
              final member = widget.members[index];
              final uid = member['user_id'];
              final amount =
                  (widget.amount * (_userPercentages[uid] ?? 0)) / 100;

              return _buildMemberRow(
                member,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 70,
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          suffixText: '%',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 8,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _userPercentages[uid] = double.tryParse(val) ?? 0.0;
                          });
                        },
                        controller:
                            TextEditingController(
                                text: (_userPercentages[uid] ?? 0)
                                    .toStringAsFixed(1),
                              )
                              ..selection = TextSelection.collapsed(
                                offset: (_userPercentages[uid] ?? 0)
                                    .toStringAsFixed(1)
                                    .length,
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Rs${amount.toInt()}",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSharesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.members.length,
      itemBuilder: (context, index) {
        final member = widget.members[index];
        final uid = member['user_id'];
        final shares = _userShares[uid] ?? 0;

        return _buildMemberRow(
          member,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.teal600,
                onPressed: () {
                  if (shares > 0) setState(() => _userShares[uid] = shares - 1);
                },
              ),
              Text(
                "$shares shares",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.teal600,
                onPressed: () {
                  setState(() => _userShares[uid] = shares + 1);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemberRow(Map<String, dynamic> member, Widget trailing) {
    final profile = member['profiles'] ?? {};
    final name = profile['full_name'] as String? ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.teal50,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.oi(color: AppColors.teal800, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
