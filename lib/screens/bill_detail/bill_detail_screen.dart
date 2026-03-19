// lib/screens/bill_detail/bill_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/categories.dart';
import '../../models/bill.dart';
import '../../providers/bills_provider.dart';
import '../../widgets/bill_item_row.dart';
import '../add_edit_bill/add_edit_bill_screen.dart';

class BillDetailScreen extends ConsumerWidget {
  final Bill bill;

  const BillDetailScreen({super.key, required this.bill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emoji = kCategoryEmoji[bill.category] ?? '📦';
    final amount = kAmountFormat.format(bill.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('詳細'),
        actions: [
          // 编辑按钮
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditBillScreen(bill: bill),
                ),
              );
              if (updated == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
          // 删除按钮
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 金额卡片
            _AmountCard(
              emoji: emoji,
              amount: amount,
              currency: bill.currency,
              category: bill.category,
            ),
            const SizedBox(height: 16),

            // 基本信息
            _InfoSection(bill: bill),
            const SizedBox(height: 16),

            // 图片凭证
            if (bill.hasReceipt) ...[
              _SectionTitle(title: '凭证'),
              const SizedBox(height: 8),
              _ReceiptImage(url: bill.receiptUrl),
              const SizedBox(height: 16),
            ],

            // 商品明细
            if (bill.items.isNotEmpty) ...[
              _SectionTitle(title: '明細 (${bill.items.length}件)'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: bill.items
                        .map((item) => BillItemRow.fromModel(item))
                        .toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この記録を削除しますか？この操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(billsProvider.notifier).deleteBill(bill.id);
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    }
  }
}

// ── 子组件 ────────────────────────────────────────────────────────────────

class _AmountCard extends StatelessWidget {
  final String emoji;
  final String amount;
  final String currency;
  final String? category;

  const _AmountCard({
    required this.emoji,
    required this.amount,
    required this.currency,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¥$amount $currency',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
                if (category != null)
                  Text(
                    category!,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final Bill bill;
  const _InfoSection({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.store_outlined,
              label: '商家',
              value: bill.merchant ?? '不明',
            ),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: '日付',
              value: bill.billDate ?? '不明',
            ),
            if (bill.description?.isNotEmpty == true)
              _InfoRow(
                icon: Icons.notes_outlined,
                label: '備考',
                value: bill.description!,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _ReceiptImage extends StatelessWidget {
  final String url;
  const _ReceiptImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _FullImageScreen(url: url),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 120,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
            ),
          ),
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// 全屏查看大图，支持双指缩放
class _FullImageScreen extends StatelessWidget {
  final String url;
  const _FullImageScreen({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5.0,
        child: Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image,
              color: Colors.white54,
              size: 60,
            ),
          ),
        ),
      ),
    );
  }
}