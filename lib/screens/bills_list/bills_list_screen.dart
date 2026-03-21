// lib/screens/bills_list/bills_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/categories.dart';
import '../../l10n/app_localizations.dart';
import '../../mixin/month_selector_mixin.dart';
import '../../providers/bills_provider.dart';
import '../../widgets/bill_item_tile.dart';
import '../add_edit_bill/add_edit_bill_screen.dart';

class BillsListScreen extends ConsumerStatefulWidget {
  const BillsListScreen({super.key});

  @override
  ConsumerState<BillsListScreen> createState() => _BillsListScreenState();
}

class _BillsListScreenState extends ConsumerState<BillsListScreen>
    with MonthSelectorMixin {
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(billsProvider.notifier).load(selectedMonth, refresh: true);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void onMonthChanged() {
    ref
        .read(billsProvider.notifier)
        .load(selectedMonth, refresh: true, keyword: _searchCtrl.text.trim());
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchCtrl.clear();
        ref
            .read(billsProvider.notifier)
            .load(selectedMonth, refresh: true, keyword: '');
      }
    });
  }

  void _onSearch(String keyword) {
    ref.read(billsProvider.notifier).search(selectedMonth, keyword.trim());
  }

  Future<void> _deleteBill(int billId) async {
    await ref.read(billsProvider.notifier).deleteBill(billId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(billsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // 统一的浅灰色背景
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0, // 滚动时取消AppBar阴影，保持扁平
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: l10n.search,
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
                onChanged: _onSearch,
                onSubmitted: _onSearch,
              )
            : Text(l10n.bills, style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions:[
          if (!_showSearch) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref
                  .read(billsProvider.notifier)
                  .load(selectedMonth, refresh: true),
            ),
          ],
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680), // 宽屏保护
          child: Column(
            children:[
              // 1. 月度汇总卡片 (搜索模式下隐藏)
              if (!_showSearch) _buildSummaryDashboard(context, l10n, state),

              // 2. 列表区域
              Expanded(
                child: state.error != null
                    ? _buildErrorState(state, l10n)
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(billsProvider.notifier)
                            .load(selectedMonth, refresh: true),
                        child: state.bills.isEmpty && !state.loading
                            ? _buildEmptyState(l10n)
                            : _buildList(state, l10n),
                      ),
              ),

              if (state.loading && state.bills.isEmpty)
                const LinearProgressIndicator(),
            ],
          ),
        ),
      ),

      // 悬浮按钮，稍微增加一点圆角和阴影使其更现代
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddEditBillScreen()),
          );
          if (created == true) {
            ref.read(billsProvider.notifier).load(selectedMonth, refresh: true);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── 子组件 ────────────────────────────────────────────────────────────

  // 现代化的仪表盘卡片
  Widget _buildSummaryDashboard(BuildContext context, AppLocalizations l10n, BillsState state) {
    final totalText = kAmountFormat.format(state.monthTotal);

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
            children:[
              // 月份切换器
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:[
                  IconButton(
                    onPressed: prevMonth,
                    icon: const Icon(Icons.chevron_left),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        minimumSize: const Size(40, 40)),
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
                        backgroundColor: Colors.grey.shade100,
                        minimumSize: const Size(40, 40)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 金额与件数
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(l10n.totalExpense,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(width: 12),
                  Text(
                    '¥$totalText',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.records(state.monthCount),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(BillsState state, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80, top: 4), // 避开FAB
      itemCount: state.bills.length + (state.hasNext ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 8), // 卡片之间的间距
      itemBuilder: (context, index) {
        if (index == state.bills.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.tonal(
              onPressed: () =>
                  ref.read(billsProvider.notifier).loadMore(selectedMonth),
              child: Text(l10n.seeMore),
            ),
          );
        }

        final bill = state.bills[index];
        return Dismissible(
          key: ValueKey(bill.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.symmetric(horizontal: 16), // 与卡片的边距对齐
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(16), // 与卡片的圆角一致
            ),
            child: const Icon(Icons.delete_outline,
                color: Colors.white, size: 28),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.deleteConfirm),
                content: Text(l10n.deleteThisRecord),
                actions:[
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.delete),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) => _deleteBill(bill.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BillItemTile(bill: bill),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:[
              Icon(Icons.receipt_long_outlined,
                  size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(l10n.noRecords, style: TextStyle(color: Colors.grey[500])),
              if (_showSearch) ...[
                const SizedBox(height: 8),
                Text(l10n.tryDifferentKeyword,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BillsState state, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:[
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(state.error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () =>
                ref.read(billsProvider.notifier).load(selectedMonth, refresh: true),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}