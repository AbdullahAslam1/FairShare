import 'package:flutter/material.dart';
import 'package:fairshare/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _expenseReminders = true;
  bool _groupUpdates = true;
  String _selectedCurrency = 'Rs';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _expenseReminders = prefs.getBool('expense_reminders') ?? true;
      _groupUpdates = prefs.getBool('group_updates') ?? true;
      _selectedCurrency = prefs.getString('currency') ?? 'Rs';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notifications Section
            Text(
              'Notifications',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    'Enable Notifications',
                    'Receive all app notifications',
                    Icons.notifications_outlined,
                    _notificationsEnabled,
                    (value) {
                      setState(() => _notificationsEnabled = value);
                      _saveSetting('notifications_enabled', value);
                    },
                  ),
                  if (_notificationsEnabled) ...[
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.border,
                    ),
                    _buildSwitchTile(
                      'Email Notifications',
                      'Receive notifications via email',
                      Icons.email_outlined,
                      _emailNotifications,
                      (value) {
                        setState(() => _emailNotifications = value);
                        _saveSetting('email_notifications', value);
                      },
                    ),
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.border,
                    ),
                    _buildSwitchTile(
                      'Push Notifications',
                      'Receive push notifications',
                      Icons.phone_android_outlined,
                      _pushNotifications,
                      (value) {
                        setState(() => _pushNotifications = value);
                        _saveSetting('push_notifications', value);
                      },
                    ),
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.border,
                    ),
                    _buildSwitchTile(
                      'Expense Reminders',
                      'Get reminded about pending expenses',
                      Icons.receipt_long_outlined,
                      _expenseReminders,
                      (value) {
                        setState(() => _expenseReminders = value);
                        _saveSetting('expense_reminders', value);
                      },
                    ),
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.border,
                    ),
                    _buildSwitchTile(
                      'Group Updates',
                      'Notifications about group activities',
                      Icons.group_outlined,
                      _groupUpdates,
                      (value) {
                        setState(() => _groupUpdates = value);
                        _saveSetting('group_updates', value);
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Preferences Section
            Text(
              'Preferences',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSelectTile(
                    'Currency',
                    _selectedCurrency,
                    Icons.attach_money_rounded,
                    () async {
                      final currency = await showDialog<String>(
                        context: context,
                        builder: (context) => _CurrencyPickerDialog(
                          selectedCurrency: _selectedCurrency,
                        ),
                      );
                      if (currency != null) {
                        setState(() => _selectedCurrency = currency);
                        _saveSetting('currency', currency);
                      }
                    },
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.border,
                  ),
                  _buildSelectTile(
                    'Language',
                    'English',
                    Icons.language_rounded,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Language selection coming soon'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Privacy Section
            Text(
              'Privacy',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildActionTile(
                    'Privacy Policy',
                    Icons.privacy_tip_outlined,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Privacy Policy coming soon'),
                        ),
                      );
                    },
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.border,
                  ),
                  _buildActionTile(
                    'Terms of Service',
                    Icons.description_outlined,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Terms of Service coming soon'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.teal600.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: AppColors.teal600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.teal600,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectTile(
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.teal600.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: AppColors.teal600),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.teal600.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: AppColors.teal600),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyPickerDialog extends StatelessWidget {
  final String selectedCurrency;

  const _CurrencyPickerDialog({required this.selectedCurrency});

  @override
  Widget build(BuildContext context) {
    final currencies = [
      {'symbol': 'Rs', 'name': 'Pakistani Rupee (PKR)'},
      {'symbol': '\$', 'name': 'US Dollar (USD)'},
      {'symbol': '€', 'name': 'Euro (EUR)'},
      {'symbol': '£', 'name': 'British Pound (GBP)'},
      {'symbol': '¥', 'name': 'Japanese Yen (JPY)'},
    ];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Select Currency',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: currencies.map((currency) {
          final isSelected = currency['symbol'] == selectedCurrency;
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.teal600.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  currency['symbol']!,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.teal600 : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            title: Text(
              currency['name']!,
              style: GoogleFonts.inter(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.teal600 : AppColors.textPrimary,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: AppColors.teal600)
                : null,
            onTap: () => Navigator.pop(context, currency['symbol']),
          );
        }).toList(),
      ),
    );
  }
}
