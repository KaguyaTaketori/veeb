import 'package:intl/intl.dart';

const _noDecimalCurrencies = {'JPY', 'KRW', 'VND'};

String formatAmount(double amount, String currency) {
  if (_noDecimalCurrencies.contains(currency.toUpperCase())) {
    return NumberFormat('#,###').format(amount.round());
  }
  return NumberFormat('#,##0.00').format(amount);
}
