class CurrencyUtils {
  static String formatPKR(double amount) {
    return 'PKR ${amount.toStringAsFixed(0)}';
  }

  static String formatUSD(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  static double parsePKR(String amount) {
    // Remove 'PKR ' prefix and parse to double
    final numericString = amount.replaceAll('PKR ', '');
    return double.parse(numericString);
  }

  static double parseUSD(String amount) {
    // Remove '$' prefix and parse to double
    final numericString = amount.replaceAll('\$', '');
    return double.parse(numericString);
  }
}
