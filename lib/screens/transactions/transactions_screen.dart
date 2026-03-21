// lib/screens/transactions/transactions_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../mixin/month_selector_mixin.dart';
import '../../models/transaction.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/group_provider.dart';
import '../../utils/currency.dart';
import '../../widgets/ui_core/vee_card.dart';
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
  String? _typeFilter;

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

  AppBar _buildAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: _showSearch
          ? TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '${l10n.note}・${l10n.category}${l10n.search}',
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
          : Text(l10n.transactions, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildSummaryCard(BuildContext context, TransactionsState state) {
    final l10n = AppLocalizations.of(context)!;
    final expenseStr = formatAmount(state.monthExpense, 'JPY');
    final incomeStr  = formatAmount(state.monthIncome,  'JPY');
    final netStr     = formatAmount(
        (state.monthIncome - state.monthExpense).abs(), 'JPY');
    final isPositive = state.monthIncome >= state.monthExpense;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: VeeCard(
        padding: const EdgeInsets.all(20),
        child: Column(
            children: [
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
                    l10n.yearMonthFormat(selectedMonth.year, selectedMonth.month),
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
              Row(
                children: [
                  Expanded(child: _SummaryCell(label: l10n.expense, value: '¥$expenseStr',
                      color: Colors.red.shade400)),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  Expanded(child: _SummaryCell(label: l10n.income, value: '¥$incomeStr',
                      color: Colors.green.shade600)),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${l10n.balance} ', style: TextStyle(
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
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${state.monthCount} ${l10n.recordCount}',
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
    );
  }

  Widget _buildTypeFilter() {
    final l10n = AppLocalizations.of(context)!;
    final filters = [
      (null,       l10n.total),
      ('expense',  l10n.expense),
      ('income',   l10n.income),
      ('transfer', l10n.transfer),
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
                            .withValues(alpha: 0.12)
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

  Widget _buildList(TransactionsState state) {
    final l10n = AppLocalizations.of(context)!;
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
              child: Text(l10n.loadMore),
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
              title: Text(l10n.deleteConfirm),
              content: Text(l10n.deleteThisRecord),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.delete),
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

  Widget _buildEmpty() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
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
                Text(l10n.noTransactions,
                    style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildError(String error) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => _load(refresh: true),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
  }
}

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

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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

    return VeeCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.categoryName ?? l10n.pleaseSelect,
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
                      l10n.monthDayJapaneseFormat(t.date.month, t.date.day),
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
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
}

class _NoGroupPlaceholder extends StatelessWidget {
  final VoidCallback onCreateGroup;
  const _NoGroupPlaceholder({required this.onCreateGroup});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.book_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 20),
                Text(l10n.noGroups,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(l10n.enterInviteCode,
                    style: TextStyle(color: Colors.grey[500]),
                    textAlign: TextAlign.center),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: onCreateGroup,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.createNewGroup,
                        style: const TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
