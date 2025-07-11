import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _currencyWithDecimalFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 2,
  );

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  // Currency formatting
  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  static String formatCurrencyWithDecimal(double amount) {
    return _currencyWithDecimalFormat.format(amount);
  }

  // Date formatting
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime.toLocal());
  }

  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }

  // Number formatting
  static String formatNumber(num number) {
    return NumberFormat('#,##0').format(number);
  }

  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  // Parse currency string back to double
  static double parseCurrency(String currencyString) {
    String cleanString = currencyString
        .replaceAll('Rp', '')
        .replaceAll(' ', '')
        .replaceAll(',', '');
    return double.tryParse(cleanString) ?? 0.0;
  }

  // Relative time formatting
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  // Transaction ID formatting
  static String formatTransactionId(int id) {
    return 'TRX${id.toString().padLeft(6, '0')}';
  }

  // Quantity formatting
  static String formatQuantity(int quantity) {
    return '${quantity}x';
  }
}
