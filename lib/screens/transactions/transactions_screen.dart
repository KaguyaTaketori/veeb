// lib/screens/transactions/transactions_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/categories.dart';
import '../../mixin/month_selector_mixin.dart';
import '../../models/transaction.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/group_provider.dart';
import '../../utils/currency.dart';
import 'add_edit_transaction_screen.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen>
    with MonthSelectorMixin {
  final _searchCtrl = TextEditingController();
  bool   _showSearch  = false;
  String? _typeFilter; // null=全部 / income / expense

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(refresh: true));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void onMonthChanged() => _load(refresh: true);

  void _load({bool refresh = false}) {
    ref.read(transactionsProvider.notifier).load(
          selectedMonth,
          refresh:    refresh,
          keyword:    _searchCtrl.text.trim(),
          typeFilter: _typeFilter,
        );
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchCtrl.clear();
        _load(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state   = ref.watch(transactionsProvider);
    final groupId = ref.watch(currentGroupIdProvider);

    // 尚未加入账本时引导创建
    if (groupId == null && !ref.watch(groupProvider).loading) {
      return _NoGroupPlaceholder(
        onCreateGroup: () =>
            ref.read(groupProvider.notifier).createDefault(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(context),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              if (!_showSearch) _buildSummaryCard(context, state),
              _buildTypeFilter(),
              Expanded(
                child: state.error != null
                    ? _buildError(state.error!)
                    : RefreshIndicator(
                        onRefresh: () async => _load(refresh: true),
                        child: state.transactions.isEmpty && !state.loading
                            ? _buildEmpty()
                            : _buildList(state),
                      ),
              ),
              if (state.loading && state.transactions.isEmpty)
                const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditTransactionScreen(
                selectedMonth: selectedMonth,
              ),
            ),
          );
          if (created == true) _load(refresh: true);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────────────

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: _showSearch
          ? TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '备注・分类で検索',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _toggleSearch,
                ),
              ),
              onChanged: (v) => ref
                  .read(transactionsProvider.notifier)
                  .search(selectedMonth, v.trim()),
            )
          : const Text('流水', style: TextStyle(fontWeight: FontWeight.bold)),
      actions: _showSearch
          ? []
          : [
              IconButton(
                  icon: const Icon(Icons.search), onPressed: _toggleSearch),
              IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _load(refresh: true)),
            ],
    );
  }

  // ── 月度汇总卡片 ──────────────────────────────────────────────────────────

  Widget _buildSummaryCard(BuildContext context, TransactionsState state) {
    final expenseStr = formatAmount(state.monthExpense, 'JPY');
    final incomeStr  = formatAmount(state.monthIncome,  'JPY');
    final netStr     = formatAmount(
        (state.monthIncome - state.monthExpense).abs(), 'JPY');
    final isPositive = state.monthIncome >= state.monthExpense;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 月份选择器
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: prevMonth,
                    icon: const Icon(Icons.chevron_left),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100),
                  ),
                  Text(
                    '${selectedMonth.year}年 ${selectedMonth.month}月',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: nextMonth,
                    icon: const Icon(Icons.chevron_right),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 支出 / 收入
              Row(
                children: [
                  Expanded(child: _SummaryCell(label: '支出', value: '¥$expenseStr',
                      color: Colors.red.shade400)),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  Expanded(child: _SummaryCell(label: '收入', value: '¥$incomeStr',
                      color: Colors.green.shade600)),
                ],
              ),
              const Divider(height: 20),
              // 结余
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('结余 ', style: TextStyle(
                      fontSize: 13, color: Colors.grey[600])),
                  Text(
                    '${isPositive ? "+" : "-"}¥$netStr',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isPositive
                          ? Colors.green.shade600
                          : Colors.red.shade400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${state.monthCount} 件',
                      style: TextStyle(
                          fontSize: 11,
                          color:
                              Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 类型筛选 Tab ──────────────────────────────────────────────────────────

  Widget _buildTypeFilter() {
    final filters = [
      (null,       '全部'),
      ('expense',  '支出'),
      ('income',   '收入'),
      ('transfer', '转账'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final selected = _typeFilter == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _typeFilter = f.$1);
                  _load(refresh: true);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.12)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(f.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[700],
                      )),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── 列表 ──────────────────────────────────────────────────────────────────

  Widget _buildList(TransactionsState state) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80, top: 4),
      itemCount:
          state.transactions.length + (state.hasNext ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        if (i == state.transactions.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.tonal(
              onPressed: () => ref
                  .read(transactionsProvider.notifier)
                  .loadMore(selectedMonth),
              child: const Text('もっと見る'),
            ),
          );
        }
        final txn = state.transactions[i];
        return Dismissible(
          key: ValueKey(txn.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline,
                color: Colors.white, size: 28),
          ),
          confirmDismiss: (_) => showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('削除確認'),
              content: const Text('この記録を削除しますか？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('削除'),
                ),
              ],
            ),
          ),
          onDismissed: (_) => ref
              .read(transactionsProvider.notifier)
              .deleteTransaction(txn.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _TransactionTile(
              transaction: txn,
              onTap: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TransactionDetailScreen(transaction: txn),
                  ),
                );
                if (updated == true) _load(refresh: true);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('記録がありません',
                    style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          ),
        ),
      );

  Widget _buildError(String error) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => _load(refresh: true),
              child: const Text('再試行'),
            ),
          ],
        ),
      );
}


// ── 汇总单元格 ────────────────────────────────────────────────────────────────

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;

  const _SummaryCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ],
      );
}


// ── 流水列表 Tile ─────────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t       = transaction;
    final icon    = t.categoryIcon ?? '📦';
    final color   = _parseColor(t.categoryColor);
    final isExp   = t.type == 'expense';
    final isTrans = t.type == 'transfer';
    final amtColor = isTrans
        ? Colors.blue
        : isExp
            ? Colors.red.shade400
            : Colors.green.shade600;
    final prefix  = isTrans ? '↔' : (isExp ? '-' : '+');

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 分类图标
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              // 分类名 + 备注 + 日期
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.categoryName ?? '未分類',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    if (t.note?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        t.note!,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(t.date),
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              // 金额
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$prefix ${t.currencyCode} ${t.formattedAmount}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: amtColor,
                    ),
                  ),
                  if (t.hasReceipt)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.image_outlined,
                          size: 14, color: Colors.grey[400]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null) return Colors.grey;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.month}月${dt.day}日';
}


// ── 未加入账本占位页 ──────────────────────────────────────────────────────────

class _NoGroupPlaceholder extends StatelessWidget {
  final VoidCallback onCreateGroup;
  const _NoGroupPlaceholder({required this.onCreateGroup});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.book_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 20),
                const Text('まだ家計簿に参加していません',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('新しく作成するか、招待コードで参加してください',
                    style: TextStyle(color: Colors.grey[500]),
                    textAlign: TextAlign.center),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: onCreateGroup,
                    icon: const Icon(Icons.add),
                    label: const Text('新しい家計簿を作成',
                        style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}