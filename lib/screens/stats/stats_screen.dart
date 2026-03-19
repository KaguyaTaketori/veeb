import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/categories.dart';
import '../../mixin/month_selector_mixin.dart';
import '../../providers/stats_provider.dart';
import '../../models/bill.dart' show MonthlySummary;

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

// ✅ 修复 #2：使用 MonthSelectorMixin
class _StatsScreenState extends ConsumerState<StatsScreen>
    with MonthSelectorMixin {
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statsProvider.notifier).load(selectedMonth);
    });
  }

  @override
  void onMonthChanged() {
    ref.read(statsProvider.notifier).load(selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('統計'), centerTitle: false),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(state.error!,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () =>
                        ref.read(statsProvider.notifier).load(selectedMonth),
                    child: const Text('再試行'),
                  ),
                ]))
              : state.summary == null
                  ? const Center(child: Text('データなし'))
                  : _Body(
                      summary: state.summary!,
                      selectedMonth: selectedMonth,
                      touchedIndex: _touchedIndex,
                      onTouch: (i) => setState(() => _touchedIndex = i),
                      onPrev: prevMonth,   // ✅ 来自 mixin
                      onNext: nextMonth,   // ✅ 来自 mixin
                    ),
    );
  }
}

class _Body extends StatelessWidget {
  final MonthlySummary summary;
  final DateTime selectedMonth;
  final int touchedIndex;
  final ValueChanged<int> onTouch;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _Body({
    required this.summary,
    required this.selectedMonth,
    required this.touchedIndex,
    required this.onTouch,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final total = kAmountFormat.format(summary.total);
    final currency = summary.byCurrency.isNotEmpty
        ? summary.byCurrency.first.currency
        : 'JPY';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Text('${selectedMonth.year}年${selectedMonth.month}月',
              style: Theme.of(context).textTheme.titleMedium),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ]),
        const SizedBox(height: 8),
        Center(
          child: Column(children: [
            Text('支出合計', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            Text(
              '¥$total $currency',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary),
            ),
            Text('${summary.count} 件',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 24),
        if (summary.byCategory.isNotEmpty) ...[
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    onTouch(response?.touchedSection != null
                        ? response!.touchedSection!.touchedSectionIndex
                        : -1);
                  },
                ),
                sections: summary.byCategory.asMap().entries.map((e) {
                  final i = e.key;
                  final cat = e.value;
                  final isTouched = i == touchedIndex;
                  final color = kCategoryColors[i % kCategoryColors.length];
                  final pct = summary.total > 0
                      ? cat.total / summary.total * 100
                      : 0.0;
                  return PieChartSectionData(
                    color: color,
                    value: cat.total,
                    radius: isTouched ? 80 : 65,
                    title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  );
                }).toList(),
                centerSpaceRadius: 50,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...summary.byCategory.asMap().entries.map((e) {
            final i = e.key;
            final cat = e.value;
            final color = kCategoryColors[i % kCategoryColors.length];
            final emoji = kCategoryEmoji[cat.category] ?? '📦';
            final catAmount = kAmountFormat.format(cat.total);
            final pct = summary.total > 0 ? cat.total / summary.total * 100 : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text('$emoji ${cat.category}',
                    style: const TextStyle(fontSize: 14)),
                const Spacer(),
                Text('¥$catAmount',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  child: Text('${pct.toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ),
              ]),
            );
          }),
        ] else
          const Center(child: Text('データなし')),
      ]),
    );
  }
}