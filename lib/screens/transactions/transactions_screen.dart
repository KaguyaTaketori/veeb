import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:skeletonizer/skeletonizer.dart';
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
import 'new_transaction_sheet.dart';

// ── 骨架占位数据 ──────────────────────────────────────────────────────────────

final _fakeTxn = Transaction(
  id: 0,
  type: 'expense',
  amount: 1280,
  currencyCode: 'JPY',
  baseAmount: 1280,
  accountId: 0,
  categoryId: 0,
  userId: 0,
  groupId: 0,
  transactionDate: 0,
  createdAt: 0,
  updatedAt: 0,
  categoryName: '餐饮消费',
  categoryIcon: '🍜',
  categoryColor: '#E85D30',
  payee: '商家名称',
);

final _fakeTxns = List.generate(7, (i) => _fakeTxn.copyWith(id: i));

// ─────────────────────────────────────────────────────────────────────────────

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

  late final PagingController<int, Transaction> _pagingController;

  static const _filterValues = <String?>[null, 'expense', 'income', 'transfer'];

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
    _pagingController = PagingController<int, Transaction>(
      getNextPageKey: (PagingState<int, Transaction>? state) {
        if (state == null) return 1;
        if (state.lastPageIsEmpty) return null;
        return state.nextIntPageKey;
      },
      fetchPage: (int pageKey) async {
        final notifier = ref.read(transactionsProvider.notifier);
        if (pageKey == 1) {
          await notifier.load(
            selectedMonth,
            refresh: true,
            keyword: _searchCtrl.text.trim(),
            typeFilter: _typeFilter,
          );
        } else {
          await notifier.loadMore(selectedMonth);
        }
        final state = ref.read(transactionsProvider);
        return state.transactions;
      },
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void onMonthChanged() => _refresh();

  void _onMonthSelected(DateTime picked) {
    if (picked.year == selectedMonth.year &&
        picked.month == selectedMonth.month) {
      return;
    }
    setState(() => selectedMonth = picked);
    onMonthChanged();
  }

  void _refresh() {
    _pagingController.refresh();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchCtrl.clear();
        _refresh();
      }
    });
  }

  Future<void> _openNewTransactionSheet() async {
    final saved = await showNewTransactionSheet(
      context,
      selectedMonth: selectedMonth,
    );
    if (saved == true) _refresh();
  }

  Future<void> _openTransactionDetail(Transaction txn) async {
    final updated = await context.push<bool>(
      '/transaction-detail',
      extra: {'transaction': txn, 'isReadOnly': true},
    );
    if (updated == true) _refresh();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summaryState = ref.watch(transactionsProvider);
    final groupId = ref.watch(currentGroupIdProvider);

    ref.listen<int?>(currentGroupIdProvider, (previous, next) {
      if (previous == null && next != null) _refresh();
    });

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
              _buildSummaryCard(context, summaryState, l10n),
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
                    _refresh();
                  },
                ),
              ),
              Expanded(child: _buildPagedList(context, l10n)),
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

  // ── AppBar ────────────────────────────────────────────────────────────────

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
              onChanged: (v) {
                _refresh();
              },
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
                onPressed: _refresh,
                tooltip: l10n.retry,
              ),
            ],
    );
  }

  // ── 汇总卡（月度收支摘要）────────────────────────────────────────────────

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

  // ── 分页列表 ──────────────────────────────────────────────────────────────

  Widget _buildPagedList(BuildContext context, AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: PagingListener(
        controller: _pagingController,
        builder: (context, state, fetchNextPage) =>
            PagedListView<int, Transaction>(
              state: state,
              fetchNextPage: fetchNextPage,
              padding: const EdgeInsets.only(
                bottom: VeeTokens.s80,
                top: VeeTokens.s4,
              ),
              builderDelegate: PagedChildBuilderDelegate<Transaction>(
                itemBuilder: (context, txn, index) => Padding(
                  padding: VeeTokens.pageHorizontal,
                  child: _buildSlidableTile(context, txn, l10n),
                ),
                firstPageProgressIndicatorBuilder: (_) => Skeletonizer(
                  enabled: true,
                  containersColor: VeeTokens.surfaceSunken,
                  child: Column(
                    children: _fakeTxns
                        .map(
                          (txn) => Padding(
                            padding: const EdgeInsets.only(
                              left: VeeTokens.s16,
                              right: VeeTokens.s16,
                              bottom: VeeTokens.spacingXs,
                            ),
                            child: _TransactionTile(
                              transaction: txn,
                              onTap: () {},
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                newPageProgressIndicatorBuilder: (_) => const Padding(
                  padding: EdgeInsets.all(VeeTokens.spacingMd),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                noItemsFoundIndicatorBuilder: (_) => VeeEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: l10n.noTransactions,
                ),
                firstPageErrorIndicatorBuilder: (_) => VeeEmptyState(
                  icon: Icons.error_outline,
                  title: _pagingController.error?.toString() ?? '加载失败',
                  iconColor: VeeTokens.error,
                  actionLabel: l10n.retry,
                  onAction: _refresh,
                ),
                newPageErrorIndicatorBuilder: (_) => Padding(
                  padding: VeeTokens.cardPadding,
                  child: FilledButton.tonal(
                    onPressed: _refresh,
                    child: Text(l10n.retry),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  // ── Slidable 瓦片 ────────────────────────────────────────────────────────

  Widget _buildSlidableTile(
    BuildContext context,
    Transaction txn,
    AppLocalizations l10n,
  ) {
    return Slidable(
      key: ValueKey(txn.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) async {
              HapticFeedback.mediumImpact();
              final ok = await VeeConfirmDialog.showDelete(
                context: context,
                content: l10n.deleteThisRecord,
              );
              if (ok == true) {
                ref
                    .read(transactionsProvider.notifier)
                    .deleteTransaction(txn.id);
              }
            },
            backgroundColor: VeeTokens.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: '删除',
            borderRadius: VeeTokens.cardBorderRadius,
          ),
        ],
      ),
      child: _TransactionTile(
        transaction: txn,
        onTap: () => _openTransactionDetail(txn),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TransactionTile
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
                  const Icon(
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

// ─────────────────────────────────────────────────────────────────────────────
// _NoGroupPlaceholder
// ─────────────────────────────────────────────────────────────────────────────

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
