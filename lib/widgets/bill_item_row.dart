import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../constants/categories.dart';

class BillItemRow extends StatelessWidget {
  final String name;
  final double amount;
  final String itemType;
  final double quantity;

  const BillItemRow({
    super.key,
    required this.name,
    required this.amount,
    this.itemType = 'item',
    this.quantity = 1.0,
  });

  factory BillItemRow.fromModel(BillItem item) => BillItemRow(
        name: item.name,
        amount: item.amount,
        itemType: item.itemType,
        quantity: item.quantity,
      );


  @override
  Widget build(BuildContext context) {
    final isDiscount = itemType == 'discount';
    final isTax = itemType == 'tax';
    final amountStr = kAmountFormat.format(amount.abs());
    final color = isDiscount
        ? Colors.red
        : isTax
            ? Colors.grey
            : Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text(
          isDiscount ? '➖' : isTax ? '🧾' : '•',
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(name, style: TextStyle(fontSize: 13, color: color)),
        ),
        if (quantity != 1.0)
          Text(
            'x${quantity.toInt()}  ',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        Text(
          isDiscount ? '-¥$amountStr' : '¥$amountStr',
          style: TextStyle(
              fontSize: 13, color: color, fontWeight: FontWeight.w500),
        ),
      ]),
    );
  }
}