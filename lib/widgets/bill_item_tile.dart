import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../constants/categories.dart';
import 'bill_item_row.dart';

class BillItemTile extends StatelessWidget {
  final Bill bill;
  const BillItemTile({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final emoji = kCategoryEmoji[bill.category] ?? '📦';
    final amount = kAmountFormat.format(bill.amount);
    final merchant = bill.displayMerchant;
    final date = bill.billDate ?? '';

    return ExpansionTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 28)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              merchant.isNotEmpty ? merchant : (bill.category ?? '未分類'),
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '¥$amount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      subtitle: Text(date, style: Theme.of(context).textTheme.bodySmall),
      children: bill.items.isEmpty
          ? []
          : [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    const Divider(),
                    ...bill.items.map((item) => BillItemRow.fromModel(item)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
    );
  }
}