// lib/screens/transactions/transactions_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../mixin/month_selector_mixin.dart';
import '../../models/transaction.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/group_provider.dart';
import '../../utils/vee_colors.dart';
import '../../widgets/ui_core/vee_card.dart';
import '../../widgets/ui_core/vee_chip.dart';
import '../../widgets/ui_core/vee_confirm_dialog.dart';
import '../../widgets/ui_core/vee_empty_state.dart';
import '../../widgets/ui_core/vee_month_selector.dart';
import '../../widgets/ui_core/vee_amount_display.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_text_styles.dart';
import 'add_edit_transaction_screen.dart';
import 'new_transaction_sheet.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen>
    with MonthSelectorMixin {
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;
  String? _typeFilter;

  static const _filterValues = <String?>[null, 'expense', 'income', 'transfer'];

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
    ref
        .read(transactionsProvider.notifier)
        .load(
          selectedMonth,
          refresh: refresh,
          keyword: _searchCtrl.text.trim(),
          typeFilter: _typeFilter,
        );
  }

  void _onMonthSelected(DateTime picked) {
    if (picked.year == selectedMonth.year &&
        picked.month == selectedMonth.month) {
      return;
    }
    setState(() => selectedMonth = picked);
    onMonthChanged();
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

  Future<void> _openNewTransactionSheet() async {
    final saved = await showNewTransactionSheet(
      context,
      selectedMonth: selectedMonth,
    );
    if (saved == true) _load(refresh: true);
  }

  Future<void> _openTransactionDetail(Transaction txn) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddEditTransactionScreen(transaction: txn, isReadOnly: true),
      ),
    );
    if (updated == true) _load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(transactionsProvider);
    final groupId = ref.watch(currentGroupIdProvider);

    if (groupId == null && !ref.watch(groupProvider).loading) {
      return _NoGroupPlaceholder(
        onCreateGroup: () => ref.read(groupProvider.notifier).createDefault(),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(context, l10n),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: VeeTokens.maxContentWidth,
          ),
          child: Column(
            children: [
              if (!_showSearch) _buildSummaryCard(context, state, l10n),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VeeTokens.s16,
                  0,
                  VeeTokens.s16,
                  VeeTokens.s8,
                ),
                child: VeeChipGroup<String?>(
                  items: _filterValues,
                  labelBuilder: (v) => switch (v) {
                    'expense' => l10n.expense,
                    'income' => l10n.income,
                    'transfer' => l10n.transfer,
                    _ => l10n.total,
                  },
                  selected: _typeFilter,
                  onChanged: (v) {
                    setState(() => _typeFilter = v);
                    _load(refresh: true);
                  },
                ),
              ),
              Expanded(
                child: state.error != null
                    ? _buildError(context, state.error!, l10n)
                    : RefreshIndicator(
                        onRefresh: () async => _load(refresh: true),
                        child: state.transactions.isEmpty && !state.loading
                            ? VeeEmptyState(
                                icon: Icons.receipt_long_outlined,
                                title: l10n.noTransactions,
                              )
                            : _buildList(context, state, l10n),
                      ),
              ),
              if (state.loading && state.transactions.isEmpty)
                const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewTransactionSheet,
        tooltip: '记一笔',
        child: const Icon(Icons.add),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, AppLocalizations l10n) {
    return AppBar(
      title: _showSearch
          ? TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '${l10n.note}・${l10n.category}・${l10n.payee}',
                prefixIcon: const Icon(Icons.search, size: VeeTokens.iconMd),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, size: VeeTokens.iconMd),
                  onPressed: _toggleSearch,
                ),
              ),
              onChanged: (v) => ref
                  .read(transactionsProvider.notifier)
                  .search(selectedMonth, v.trim()),
            )
          : Text(l10n.transactions, style: context.veeText.pageTitle),
      actions: _showSearch
          ? []
          : [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _toggleSearch,
                tooltip: l10n.search,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _load(refresh: true),
                tooltip: l10n.retry,
              ),
            ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    TransactionsState state,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VeeTokens.s16,
        VeeTokens.s4,
        VeeTokens.s16,
        VeeTokens.s12,
      ),
      child: VeeMonthSelectorCard(
        month: selectedMonth,
        canGoNext: !isCurrentMonth,
        onPrev: prevMonth,
        onNext: nextMonth,
        onMonthSelected: _onMonthSelected,
        child: Column(
          children: [
            const SizedBox(height: VeeTokens.s12),
            VeeSummaryRow(
              expense: state.monthExpense,
              income: state.monthIncome,
              currency: 'JPY',
              count: state.monthCount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    TransactionsState state,
    AppLocalizations l10n,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: VeeTokens.s80, top: VeeTokens.s4),
      itemCount: state.transactions.length + (state.hasNext ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: VeeTokens.spacingXs),
      itemBuilder: (ctx, i) {
        if (i == state.transactions.length) {
          return Padding(
            padding: VeeTokens.cardPadding,
            child: FilledButton.tonal(
              onPressed: () => ref
                  .read(transactionsProvider.notifier)
                  .loadMore(selectedMonth),
              child: Text(l10n.loadMore),
            ),
          );
        }

        final txn = state.transactions[i];
        return Padding(
          padding: VeeTokens.pageHorizontal,
          child: _SlidableRow(
            key: ValueKey(txn.id),
            onConfirmDelete: () async {
              HapticFeedback.mediumImpact();
              final ok = await VeeConfirmDialog.showDelete(
                context: context,
                content: l10n.deleteThisRecord,
              );
              return ok ?? false;
            },
            onDeleted: () => ref
                .read(transactionsProvider.notifier)
                .deleteTransaction(txn.id),
            child: _TransactionTile(
              transaction: txn,
              onTap: () => _openTransactionDetail(txn),
            ),
          ),
        );
      },
    );
  }

  Widget _buildError(
    BuildContext context,
    String error,
    AppLocalizations l10n,
  ) {
    return VeeEmptyState(
      icon: Icons.error_outline,
      title: error,
      iconColor: VeeTokens.error,
      actionLabel: l10n.retry,
      onAction: () => _load(refresh: true),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slidable row
// ─────────────────────────────────────────────────────────────────────────────

class _SlidableRow extends StatefulWidget {
  final Widget child;
  final Future<bool> Function() onConfirmDelete;
  final VoidCallback onDeleted;

  const _SlidableRow({
    super.key,
    required this.child,
    required this.onConfirmDelete,
    required this.onDeleted,
  });

  @override
  State<_SlidableRow> createState() => _SlidableRowState();
}

class _SlidableRowState extends State<_SlidableRow> {
  double _dragProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: widget.key!,
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.40},
      resizeDuration: VeeTokens.durationSlow,
      movementDuration: const Duration(milliseconds: 300),
      onUpdate: (details) {
        setState(() => _dragProgress = details.progress);
      },
      confirmDismiss: (_) => widget.onConfirmDelete(),
      onDismissed: (_) => widget.onDeleted(),
      background: AnimatedContainer(
        duration: VeeTokens.durationFast,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: VeeTokens.s24),
        decoration: BoxDecoration(
          color: VeeTokens.error.withOpacity(
            (_dragProgress / 0.40).clamp(0.0, 1.0),
          ),
          borderRadius: VeeTokens.cardBorderRadius,
        ),
        child: Semantics(
          label: '删除',
          child: AnimatedScale(
            scale: (_dragProgress / 0.40).clamp(0.4, 1.0),
            duration: VeeTokens.durationFast,
            child: Icon(
              Icons.delete_outline,
              color: Colors.white.withOpacity(
                (_dragProgress / 0.40).clamp(0.0, 1.0),
              ),
              size: VeeTokens.iconXl,
            ),
          ),
        ),
      ),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction tile
// ─────────────────────────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;
  const _TransactionTile({required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = transaction;
    final color = VeeColors.fromHex(t.categoryColor);
    final amtColor = VeeColors.forTransactionType(t.type);
    final prefix = VeeColors.prefixForTransactionType(t.type);

    // ✅ 副标题优先级：payee > note > 无
    final String? subtitle =
        t.displayPayee ?? (t.note?.isNotEmpty == true ? t.note : null);

    return VeeCard.list(
      onTap: onTap,
      child: Padding(
        padding: VeeTokens.tilePadding,
        child: Row(
          children: [
            Container(
              width: VeeTokens.touchMin,
              height: VeeTokens.touchMin,
              decoration: BoxDecoration(
                color: VeeTokens.selectedTint(color),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                t.categoryIcon ?? '📦',
                style: const TextStyle(fontSize: VeeTokens.iconLg - 4),
              ),
            ),
            const SizedBox(width: VeeTokens.spacingSm),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.categoryName ?? l10n.pleaseSelect,
                    style: context.veeText.cardTitle,
                  ),
                  // ✅ 副标题：payee 优先，fallback 到 note
                  if (subtitle != null) ...[
                    const SizedBox(height: VeeTokens.s2),
                    Text(
                      subtitle,
                      style: context.veeText.caption.copyWith(
                        color: VeeTokens.textSecondaryVal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: VeeTokens.s2),
                  Text(
                    l10n.monthDayJapaneseFormat(t.date.month, t.date.day),
                    style: context.veeText.micro.copyWith(
                      color: VeeTokens.textPlaceholderVal,
                    ),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                VeeAmountDisplay(
                  amount: t.amount,
                  currency: t.currencyCode,
                  size: VeeAmountSize.small,
                  prefix: prefix,
                  color: amtColor,
                ),
                if (t.hasReceipt) ...[
                  const SizedBox(height: VeeTokens.s2),
                  Icon(
                    Icons.image_outlined,
                    size: VeeTokens.iconXs,
                    color: VeeTokens.textPlaceholderVal,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoGroupPlaceholder extends StatelessWidget {
  final VoidCallback onCreateGroup;
  const _NoGroupPlaceholder({required this.onCreateGroup});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: VeeEmptyState(
        icon: Icons.book_outlined,
        title: l10n.noGroups,
        subtitle: l10n.enterInviteCode,
        actionLabel: l10n.createNewGroup,
        onAction: onCreateGroup,
      ),
    );
  }
}
