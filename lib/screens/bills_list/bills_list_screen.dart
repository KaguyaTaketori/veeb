// lib/screens/bills_list/bills_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/categories.dart';
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
    final state = ref.watch(billsProvider);
    final totalText = '¥${kAmountFormat.format(state.monthTotal)}';

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '商家・説明・カテゴリで検索',
                  border: InputBorder.none,
                ),
                onChanged: _onSearch,
                onSubmitted: _onSearch,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: prevMonth,
                    icon: const Icon(Icons.chevron_left, size: 20),
                  ),
                  Text('${selectedMonth.year}年${selectedMonth.month}月'),
                  IconButton(
                    onPressed: nextMonth,
                    icon: const Icon(Icons.chevron_right, size: 20),
                  ),
                ],
              ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off : Icons.search),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(billsProvider.notifier)
                .load(selectedMonth, refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // 月合计栏
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('支出合計',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  totalText,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text('${state.monthCount} 件',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),

          // 列表
          Expanded(
            child: state.error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.error!,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () => ref
                              .read(billsProvider.notifier)
                              .load(selectedMonth, refresh: true),
                          child: const Text('再試行'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(billsProvider.notifier)
                        .load(selectedMonth, refresh: true),
                    child: state.bills.isEmpty && !state.loading
                        ? const Center(child: Text('記録がありません'))
                        : ListView.builder(
                            itemCount: state.bills.length +
                                (state.hasNext ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == state.bills.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: FilledButton(
                                    onPressed: () => ref
                                        .read(billsProvider.notifier)
                                        .loadMore(selectedMonth),
                                    child: const Text('もっと見る'),
                                  ),
                                );
                              }

                              final bill = state.bills[index];
                              return Dismissible(
                                key: ValueKey(bill.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: Colors.red,
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                confirmDismiss: (_) async {
                                  return await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('削除確認'),
                                      content:
                                          const Text('この記録を削除しますか？'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('キャンセル'),
                                        ),
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('削除'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (_) => _deleteBill(bill.id),
                                child: BillItemTile(bill: bill),
                              );
                            },
                          ),
                  ),
          ),

          if (state.loading) const LinearProgressIndicator(),
        ],
      ),

      // 新建账单 FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditBillScreen(),
            ),
          );
          if (created == true) {
            ref
                .read(billsProvider.notifier)
                .load(selectedMonth, refresh: true);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}