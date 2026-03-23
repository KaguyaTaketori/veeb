import 'package:intl/intl.dart';

const Set<String> kNoDecimalCurrencies = {'JPY', 'KRW', 'VND'};

double intToFloat(int value, String currency) {
  return kNoDecimalCurrencies.contains(currency.toUpperCase())
      ? value.toDouble()
      : value / 100.0;
}

int floatToInt(double value, String currency) {
  return kNoDecimalCurrencies.contains(currency.toUpperCase())
      ? value.round()
      : (value * 100).round();
}

int rateToInt(double rate) => (rate * 1_000_000).round();
double rateFromInt(int rate) => rate / 1_000_000;

String formatAmount(double amount, String currency) {
  if (kNoDecimalCurrencies.contains(currency.toUpperCase())) {
    return NumberFormat('#,###').format(amount.round());
  }
  return NumberFormat('#,##0.00').format(amount);
}
