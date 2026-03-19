import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../constants/categories.dart';
import 'bill_item_row.dart';
import '../screens/bill_detail/bill_detail_screen.dart';

class BillItemTile extends StatelessWidget {
  final Bill bill;
  final VoidCallback? onDeleted;

  const BillItemTile({super.key, required this.bill, this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final emoji = kCategoryEmoji[bill.category] ?? '📦';
    final amount = kAmountFormat.format(bill.amount);
    final merchant = bill.displayMerchant;
    final date = bill.billDate ?? '';

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BillDetailScreen(bill: bill),
        ),
      ),
      child: ExpansionTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            // 有凭证时右下角显示图片角标
            if (bill.hasReceipt)
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.image, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
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
        children: [
          if (bill.hasReceipt || bill.items.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  // 凭证缩略图
                  if (bill.hasReceipt)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          bill.receiptUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 60,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.broken_image,
                                  color: Colors.grey),
                            ),
                          ),
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : SizedBox(
                                      height: 60,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: progress.expectedTotalBytes !=
                                                  null
                                              ? progress
                                                      .cumulativeBytesLoaded /
                                                  progress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    ),
                        ),
                      ),
                    ),
                  // 明细列表
                  ...bill.items.map((item) => BillItemRow.fromModel(item)),
                  const SizedBox(height: 8),
                ],
              ),
            ),
        ],
      ),
    );
  }
}