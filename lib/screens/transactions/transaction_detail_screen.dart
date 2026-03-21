// ─────────────────────────────────────────────────────────────────────────────
// lib/screens/transactions/transaction_detail_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/transaction.dart';
import '../../providers/transactions_provider.dart';
import '../../utils/currency.dart';
import 'add_edit_transaction_screen.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final Transaction transaction;
  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t     = transaction;
    final color = _parseColor(t.categoryColor);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text('詳細',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditTransactionScreen(
                    transaction:   t,
                    selectedMonth: t.date,
                  ),
                ),
              );
              if (updated == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('編集', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              // 类型 + 金额
              _buildAmountHeader(context, t, color),
              const SizedBox(height: 32),

              // 基本信息
              _buildInfoCard(context, t),
              const SizedBox(height: 24),

              // 凭证
              if (t.hasReceipt) ...[
                _buildSectionTitle('レシート'),
                const SizedBox(height: 12),
                _ReceiptImage(url: t.receiptUrl),
                const SizedBox(height: 24),
              ],

              // 明细
              if (t.items.isNotEmpty) ...[
                _buildSectionTitle('明細 (${t.items.length}件)'),
                const SizedBox(height: 12),
                _buildItemsCard(context, t),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 16),
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
                  onPressed: () => _confirmDelete(context, ref, t.id),
                  child: const Text('この記録を削除',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountHeader(BuildContext ctx, Transaction t, Color color) {
    final typeLabel = t.type == 'income'
        ? '収入'
        : t.type == 'transfer'
            ? '振替'
            : '支出';
    final typeColor = t.type == 'income'
        ? Colors.green
        : t.type == 'transfer'
            ? Colors.blue
            : Colors.red.shade400;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(typeLabel,
              style: TextStyle(
                  color: typeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
        const SizedBox(height: 12),
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(t.categoryIcon ?? '📦',
              style: const TextStyle(fontSize: 30)),
        ),
        const SizedBox(height: 12),
        Text(t.categoryName ?? '未分類',
            style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(t.currencyCode,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(ctx).colorScheme.primary)),
            const SizedBox(width: 8),
            Text(t.formattedAmount,
                style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    color: typeColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext ctx, Transaction t) {
    return Card(
      elevation: 0,
      color: Theme.of(ctx).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: '日付',
              value:
                  '${t.date.year}/${t.date.month.toString().padLeft(2, '0')}/${t.date.day.toString().padLeft(2, '0')}'),
          if (t.note?.isNotEmpty == true) ...[
            const Divider(height: 1, indent: 48),
            _InfoRow(
                icon: Icons.notes_outlined,
                label: '備考',
                value: t.note!),
          ],
          if (t.isPrivate) ...[
            const Divider(height: 1, indent: 48),
            _InfoRow(
                icon: Icons.lock_outline,
                label: 'プライベート',
                value: 'はい'),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsCard(BuildContext ctx, Transaction t) {
    return Card(
      elevation: 0,
      color: Theme.of(ctx).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: t.items.map((item) {
            final isDisc = item.itemType == 'discount';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Text(isDisc ? '➖' : '•',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(item.name,
                          style: const TextStyle(fontSize: 13))),
                  Text(
                    '${isDisc ? '-' : ''}${t.currencyCode} ${formatAmount(item.amount.abs(), t.currencyCode)}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDisc ? Colors.red : null),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      );

  Future<void> _confirmDelete(
      BuildContext ctx, WidgetRef ref, int id) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この記録を削除しますか？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('キャンセル')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok == true && ctx.mounted) {
      await ref.read(transactionsProvider.notifier).deleteTransaction(id);
      if (ctx.mounted) Navigator.pop(ctx, true);
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null) return Colors.grey;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext ctx) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[500]),
            const SizedBox(width: 12),
            SizedBox(
              width: 70,
              child: Text(label,
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 14)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.right),
            ),
          ],
        ),
      );
}

class _ReceiptImage extends StatelessWidget {
  final String url;
  const _ReceiptImage({required this.url});

  @override
  Widget build(BuildContext ctx) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(url,
            width: double.infinity,
            height: 160,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: Colors.grey.shade200,
                  child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey)),
                )),
      );
}