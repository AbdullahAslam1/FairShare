/// Budget utility functions
class BudgetUtils {
  /// Currency symbols map
  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'PKR': 'Rs',
    'Rs': 'Rs',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
  };

  /// Format amount with currency
  static String formatCurrency(double amount, String currency) {
    final symbol = currencySymbols[currency] ?? currency;
    return '$symbol ${amount.toStringAsFixed(0)}';
  }

  /// Format amount with 2 decimals
  static String formatCurrencyDetailed(double amount, String currency) {
    final symbol = currencySymbols[currency] ?? currency;
    return '$symbol ${amount.toStringAsFixed(2)}';
  }
}
