// lib/widgets/bill_item_tile.dart
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

    // 将整个Tile包裹在白色的圆角Card中
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface, // 白色背景
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)), // 极细的灰色边框
      ),
      margin: EdgeInsets.zero, // 外边距交由 ListView 控制
      child: Theme(
        // 去除 ExpansionTile 展开时默认的上下分割线
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          leading: _buildLeadingIcon(context, emoji, bill.hasReceipt),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Expanded(
                child: Text(
                  merchant.isNotEmpty ? merchant : (bill.category ?? '未分類'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '¥$amount',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              date,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
          // 展开内容
          children:[
            if (bill.hasReceipt || bill.items.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50, // 展开区域使用淡淡的灰色作为层次区分
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    // 凭证缩略图
                    if (bill.hasReceipt)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            bill.receiptUrl,
                            height: 100,
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
                          ),
                        ),
                      ),
                    // 明细列表
                    ...bill.items.map((item) => BillItemRow.fromModel(item)),
                    
                    const SizedBox(height: 12),
                    // 跳转详情的按钮
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BillDetailScreen(bill: bill),
                          ),
                        ),
                        child: const Text('詳細を見る', style: TextStyle(fontSize: 13)),
                      ),
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 构建带背景色的Emoji图标和图片角标
  Widget _buildLeadingIcon(BuildContext context, String emoji, bool hasReceipt) {
    return Stack(
      clipBehavior: Clip.none,
      children:[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
        if (hasReceipt)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.image, size: 10, color: Colors.white),
            ),
          ),
      ],
    );
  }
}