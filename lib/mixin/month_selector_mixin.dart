import 'package:flutter/material.dart';

mixin MonthSelectorMixin<T extends StatefulWidget> on State<T> {
  late DateTime selectedMonth;

  void onMonthChanged();

  bool get isCurrentMonth {
    final now = DateTime.now();
    return selectedMonth.year == now.year &&
        selectedMonth.month == now.month;
  }

  void prevMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month - 1,
      );
    });
    onMonthChanged();
  }

  void nextMonth() {
    if (isCurrentMonth) return;
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
      );
    });
    onMonthChanged();
  }
}