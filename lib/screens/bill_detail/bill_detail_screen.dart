// lib/screens/bill_detail/bill_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/categories.dart';
import '../../models/bill.dart';
import '../../providers/bills_provider.dart';
import '../../utils/currency.dart';
import '../../widgets/bill_item_row.dart';
import '../add_edit_bill/add_edit_bill_screen.dart';

class BillDetailScreen extends ConsumerWidget {
  final Bill bill;

  const BillDetailScreen({super.key, required this.bill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emoji  = kCategoryEmoji[bill.category] ?? '📦';
    final amount = formatAmount(bill.amount, bill.currency);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title:
            const Text('詳細', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton.icon(
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
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('編集', style: TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              _buildAmountHeader(context, emoji, amount),
              const SizedBox(height: 32),
              _buildInfoCard(context),
              const SizedBox(height: 24),

              // 凭证图片
              if (bill.hasReceipt) ...[
                _buildSectionTitle('レシート・領収書画像'),
                const SizedBox(height: 12),
                _ReceiptImage(url: bill.receiptUrl),
                const SizedBox(height: 24),
              ],

              // 明细
              if (bill.items.isNotEmpty) ...[
                _buildSectionTitle('明細 (${bill.items.length}件)'),
                const SizedBox(height: 12),
                _buildItemsCard(context),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _confirmDelete(context, ref),
                  child: const Text(
                    'この記録を削除する',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  // ── 顶部金额区域 ─────────────────────────────────────────────────────

  Widget _buildAmountHeader(
      BuildContext context, String emoji, String amount) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 36)),
        ),
        const SizedBox(height: 16),
        // 分类名
        Text(
          bill.category ?? '未分類',
          style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        // 超大金额
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              bill.currency,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amount,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                height: 1.0,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        // 来源标签（Bot 记录显示）
        if (bill.sourceLabel != null) ...[
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${bill.sourceLabel!} から記録',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ],
    );
  }

  // ── 基本信息卡片 ─────────────────────────────────────────────────────

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.store_outlined,
            label: '商家',
            value: bill.merchant ?? '未入力',
            isValueFaded:
                bill.merchant == null || bill.merchant!.isEmpty,
          ),
          const Divider(height: 1, indent: 48),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: '日付',
            value: bill.billDate ?? '不明',
          ),
          if (bill.description?.isNotEmpty == true) ...[
            const Divider(height: 1, indent: 48),
            _buildInfoRow(
              icon: Icons.notes_outlined,
              label: '備考',
              value: bill.description!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isValueFaded = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style:
                  TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isValueFaded
                    ? FontWeight.normal
                    : FontWeight.w500,
                color: isValueFaded
                    ? Colors.grey[400]
                    : Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87),
      ),
    );
  }

  // ── 明细卡片 ─────────────────────────────────────────────────────────

  Widget _buildItemsCard(BuildContext context) {
    // 明细合计（amount 已是 float）
    final itemsTotal =
        bill.items.fold(0.0, (sum, e) => sum + e.amount);
    final itemsTotalStr = formatAmount(itemsTotal, bill.currency);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...bill.items.map((item) => BillItemRow.fromModel(item, currency: bill.currency)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '明細合計',
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 13),
                ),
                Text(
                  '${bill.currency} $itemsTotalStr',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 删除确认 ─────────────────────────────────────────────────────────

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除確認'),
        content:
            const Text('この記録を削除しますか？\nこの操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除する'),
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

// ── 凭证图片组件（不变）────────────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url,
          width: double.infinity,
          height: 160,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: const Center(
              child: Icon(Icons.broken_image,
                  size: 40, color: Colors.grey),
            ),
          ),
          loadingBuilder: (_, child, progress) =>
              progress == null
                  ? child
                  : SizedBox(
                      height: 160,
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