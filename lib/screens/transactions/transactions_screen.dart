import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../mixin/month_selector_mixin.dart';
import '../../models/transaction.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/group_provider.dart';
import '../../utils/currency.dart';
import '../../widgets/ui_core/vee_card.dart';
import '../../widgets/ui_core/vee_chip.dart';
import '../../widgets/ui_core/vee_confirm_dialog.dart';
import '../../widgets/ui_core/vee_empty_state.dart';
import '../../widgets/ui_core/vee_month_selector.dart';
import '../../widgets/ui_core/vee_amount_display.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_text_styles.dart';
import 'add_edit_transaction_screen.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen>
    with MonthSelectorMixin {
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;
  String? _typeFilter;

  // 类型筛选选项
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n    = AppLocalizations.of(context)!;
    final state   = ref.watch(transactionsProvider);
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
          constraints: const BoxConstraints(maxWidth: VeeTokens.maxContentWidth),
          child: Column(children: [
            // ── 月度汇总卡（仅非搜索状态显示）──────────────────────────
            if (!_showSearch) _buildSummaryCard(context, state, l10n),

            // ── 类型筛选 Chip 栏 ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VeeTokens.s16, 0, VeeTokens.s16, VeeTokens.s8,
              ),
              child: VeeChipGroup<String?>(
                items: _filterValues,
                labelBuilder: (v) => switch (v) {
                  'expense'  => l10n.expense,
                  'income'   => l10n.income,
                  'transfer' => l10n.transfer,
                  _          => l10n.total,
                },
                selected:  _typeFilter,
                onChanged: (v) {
                  setState(() => _typeFilter = v);
                  _load(refresh: true);
                },
              ),
            ),

            // ── 列表区域 ──────────────────────────────────────────────
            Expanded(
              child: state.error != null
                  ? _buildError(context, state.error!, l10n)
                  : RefreshIndicator(
                      onRefresh: () async => _load(refresh: true),
                      child: state.transactions.isEmpty && !state.loading
                          ? VeeEmptyState(
                              icon:  Icons.receipt_long_outlined,
                              title: l10n.noTransactions,
                            )
                          : _buildList(context, state, l10n),
                    ),
            ),

            if (state.loading && state.transactions.isEmpty)
              const LinearProgressIndicator(),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
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

  // ── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(BuildContext context, AppLocalizations l10n) {
    return AppBar(
      title: _showSearch
          ? TextField(
              controller: _searchCtrl,
              autofocus:  true,
              decoration: InputDecoration(
                hintText: '${l10n.note}・${l10n.category}',
                prefixIcon: const Icon(Icons.search, size: VeeTokens.iconMd),
                suffixIcon: IconButton(
                  icon:      const Icon(Icons.close, size: VeeTokens.iconMd),
                  onPressed: _toggleSearch,
                ),
                // border / fill 继承全局 InputDecorationTheme
              ),
              onChanged: (v) => ref
                  .read(transactionsProvider.notifier)
                  .search(selectedMonth, v.trim()),
            )
          : Text(
              l10n.transactions,
              style: context.veeText.pageTitle,
            ),
      actions: _showSearch
          ? []
          : [
              IconButton(
                icon:     const Icon(Icons.search),
                onPressed: _toggleSearch,
                tooltip:  l10n.search,
              ),
              IconButton(
                icon:     const Icon(Icons.refresh),
                onPressed: () => _load(refresh: true),
                tooltip:  l10n.retry,
              ),
            ],
    );
  }

  // ── 月度汇总卡 ────────────────────────────────────────────────────────────

  Widget _buildSummaryCard(
    BuildContext context,
    TransactionsState state,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VeeTokens.s16, VeeTokens.s4, VeeTokens.s16, VeeTokens.s12,
      ),
      child: VeeMonthSelectorCard(
        month:     selectedMonth,
        canGoNext: !isCurrentMonth,
        onPrev:    prevMonth,
        onNext:    nextMonth,
        child: Column(children: [
          const SizedBox(height: VeeTokens.s12),
          VeeSummaryRow(
            expense:  state.monthExpense,
            income:   state.monthIncome,
            currency: 'JPY',
            count:    state.monthCount,
          ),
        ]),
      ),
    );
  }

  // ── 列表 ──────────────────────────────────────────────────────────────────

  Widget _buildList(
    BuildContext context,
    TransactionsState state,
    AppLocalizations l10n,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.only(
        bottom: VeeTokens.s80,
        top:    VeeTokens.s4,
      ),
      itemCount:
          state.transactions.length + (state.hasNext ? 1 : 0),
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
        return Dismissible(
          key: ValueKey(txn.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: VeeTokens.s24),
            margin: VeeTokens.pageHorizontal,
            decoration: BoxDecoration(
              color:        VeeTokens.error,
              borderRadius: VeeTokens.cardBorderRadius,
            ),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size:  VeeTokens.iconXl,
            ),
          ),
          // ── 使用 VeeConfirmDialog 替代内联 AlertDialog ────────────────
          confirmDismiss: (_) => VeeConfirmDialog.showDelete(
            context: context,
            content: l10n.deleteThisRecord,
          ),
          onDismissed: (_) => ref
              .read(transactionsProvider.notifier)
              .deleteTransaction(txn.id),
          child: Padding(
            padding: VeeTokens.pageHorizontal,
            child: _TransactionTile(
              transaction: txn,
              onTap: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditTransactionScreen(
                      transaction:   txn,
                      selectedMonth: selectedMonth,
                      isReadOnly:    true,
                    ),
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

  // ── 错误状态 ──────────────────────────────────────────────────────────────

  Widget _buildError(BuildContext context, String error, AppLocalizations l10n) {
    return VeeEmptyState(
      icon:        Icons.error_outline,
      title:       error,
      iconColor:   VeeTokens.error,
      actionLabel: l10n.retry,
      onAction:    () => _load(refresh: true),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 流水列表 Tile
// ─────────────────────────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;
  const _TransactionTile({required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context)!;
    final t     = transaction;
    final icon  = t.categoryIcon ?? '📦';
    final color = _parseColor(t.categoryColor);

    final bool isExp   = t.type == 'expense';
    final bool isTrans = t.type == 'transfer';

    final Color amtColor = isTrans
        ? VeeTokens.info
        : isExp
            ? VeeTokens.error
            : VeeTokens.success;

    final String prefix = isTrans ? '↔' : (isExp ? '-' : '+');

    return VeeCard(
      onTap:   onTap,
      padding: VeeTokens.tilePadding,
      child: Row(children: [
        // ── 分类图标 ──────────────────────────────────────────────────
        Container(
          width:  VeeTokens.touchMin,
          height: VeeTokens.touchMin,
          decoration: BoxDecoration(
            color: VeeTokens.selectedTint(color),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: VeeTokens.iconLg - 4)),
        ),
        const SizedBox(width: VeeTokens.spacingSm),

        // ── 分类名 + 备注 + 日期 ──────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.categoryName ?? l10n.pleaseSelect,
                style: context.veeText.cardTitle,
              ),
              if (t.note?.isNotEmpty == true) ...[
                const SizedBox(height: VeeTokens.s2),
                Text(
                  t.note!,
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

        // ── 金额 + 凭证角标 ───────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            VeeAmountDisplay(
              amount:   t.amount,
              currency: t.currencyCode,
              size:     VeeAmountSize.small,
              prefix:   prefix,
              color:    amtColor,
            ),
            if (t.hasReceipt) ...[
              const SizedBox(height: VeeTokens.s2),
              Icon(
                Icons.image_outlined,
                size:  VeeTokens.iconXs,
                color: VeeTokens.textPlaceholderVal,
              ),
            ],
          ],
        ),
      ]),
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

// ─────────────────────────────────────────────────────────────────────────────
// 无账本占位
// ─────────────────────────────────────────────────────────────────────────────

class _NoGroupPlaceholder extends StatelessWidget {
  final VoidCallback onCreateGroup;
  const _NoGroupPlaceholder({required this.onCreateGroup});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: VeeEmptyState(
        icon:        Icons.book_outlined,
        title:       l10n.noGroups,
        subtitle:    l10n.enterInviteCode,
        actionLabel: l10n.createNewGroup,
        onAction:    onCreateGroup,
      ),
    );
  }
}