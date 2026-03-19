// lib/screens/bills_list/bills_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/categories.dart';
import '../../mixin/month_selector_mixin.dart';
import '../../providers/bills_provider.dart';
import '../../widgets/bill_item_tile.dart';

// ✅ 修复 #1：删除 final _billsApi = BillsApi(createApiClient())

class BillsListScreen extends ConsumerStatefulWidget {
  const BillsListScreen({super.key});

  @override
  ConsumerState<BillsListScreen> createState() => _BillsListScreenState();
}

// ✅ 修复 #2：使用 MonthSelectorMixin，删除重复的 _prevMonth / _nextMonth
class _BillsListScreenState extends ConsumerState<BillsListScreen>
    with MonthSelectorMixin {

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
    // initState 中不能直接调用 ref，用 addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(billsProvider.notifier).load(selectedMonth, refresh: true);
    });
  }

  // ✅ 修复 #2：实现 mixin 的抽象方法
  @override
  void onMonthChanged() {
    ref.read(billsProvider.notifier).load(selectedMonth, refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 修复 #7：状态变更由 Notifier 统一管理，UI 只 watch
    final state = ref.watch(billsProvider);
    final totalText = '¥${kAmountFormat.format(state.monthTotal)}';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                onPressed: prevMonth, // ✅ 来自 mixin
                icon: const Icon(Icons.chevron_left, size: 20)),
            Text('${selectedMonth.year}年${selectedMonth.month}月'),
            IconButton(
                onPressed: nextMonth, // ✅ 来自 mixin
                icon: const Icon(Icons.chevron_right, size: 20)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(billsProvider.notifier).load(selectedMonth, refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('支出合計', style: Theme.of(context).textTheme.bodyMedium),
                Text(totalText,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('${state.monthCount} 件',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
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
                            itemCount:
                                state.bills.length + (state.hasNext ? 1 : 0),
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
                              return BillItemTile(bill: state.bills[index]);
                            },
                          ),
                  ),
          ),
          if (state.loading) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}