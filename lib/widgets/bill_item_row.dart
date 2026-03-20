// lib/widgets/bill_item_row.dart
import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../constants/categories.dart';
import '../utils/currency.dart';

class BillItemRow extends StatelessWidget {
  final String name;
  final double amount;
  final String itemType;
  final double quantity;
  final String currency;   // ← 新增

  const BillItemRow({
    super.key,
    required this.name,
    required this.amount,
    this.itemType = 'item',
    this.quantity = 1.0,
    this.currency = 'JPY',  // ← 默认值保持向后兼容
  });

  factory BillItemRow.fromModel(BillItem item, {String currency = 'JPY'}) =>
      BillItemRow(
        name:     item.name,
        amount:   item.amount,
        itemType: item.itemType,
        quantity: item.quantity,
        currency: currency,
      );

  @override
  Widget build(BuildContext context) {
    final isDiscount = itemType == 'discount';
    final isTax      = itemType == 'tax';
    final amountStr  = formatAmount(amount.abs(), currency);  // ← 替换原 kAmountFormat
    final color = isDiscount
        ? Colors.red
        : isTax
            ? Colors.grey
            : Theme.of(context).colorScheme.onSurface;
    // 货币符号：JPY 用 ¥，其他用货币代码
    final currencySymbol = currency == 'JPY' ? '¥' : '$currency ';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            isDiscount ? '➖' : isTax ? '🧾' : '•',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name,
                style: TextStyle(fontSize: 13, color: color)),
          ),
          if (quantity != 1.0)
            Text(
              'x${quantity.toInt()}  ',
              style:
                  TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          Text(
            isDiscount
                ? '-$currencySymbol$amountStr'
                : '$currencySymbol$amountStr',
            style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}