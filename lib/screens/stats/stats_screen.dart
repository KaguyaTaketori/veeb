// lib/screens/stats/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/categories.dart';
import '../../mixin/month_selector_mixin.dart';
import '../../providers/stats_provider.dart';
import '../../models/transaction.dart' show MonthlyStat;

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

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
    setState(() => _touchedIndex = -1); // 月を切り替えたらハイライトをリセット
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statsProvider);

    return Scaffold(
      // 編集画面と統一したモダンな背景色
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('統計'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: ConstrainedBox(
          // PC/タブレットでの横伸びを防ぐ制約
          constraints: const BoxConstraints(maxWidth: 680),
          child: state.loading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
                  ? _buildErrorState(state.error!)
                  : state.summary == null
                      ? _buildEmptyState()
                      : _Body(
                          summary: state.summary!,
                          selectedMonth: selectedMonth,
                          touchedIndex: _touchedIndex,
                          onTouch: (i) => setState(() => _touchedIndex = i),
                          onPrev: prevMonth,
                          onNext: nextMonth,
                        ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(error, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () =>
                ref.read(statsProvider.notifier).load(selectedMonth),
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:[
          Icon(Icons.bar_chart, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('データがありません', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}

// ── ボディ部（レイアウト構成） ──────────────────────────────────────────

class _Body extends StatelessWidget {
  final MonthlyStat summary;
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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children:[
        // 1. 月間サマリーカード（合計金額と月選択）
        _buildSummaryCard(context),
        const SizedBox(height: 16),

        if (summary.byCategory.isNotEmpty) ...[
          // 2. 円グラフカード
          _buildChartCard(context),
          const SizedBox(height: 16),
          // 3. カテゴリ別リストカード
          _buildCategoryListCard(context),
          const SizedBox(height: 48), // スクロール余白
        ] else ...[
          // データがない月の空ステータス
          const SizedBox(height: 48),
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'この月の記録はありません',
              style: TextStyle(color: Colors.grey[500], fontSize: 15),
            ),
          ),
        ],
      ],
    );
  }

  // ── サブコンポーネント ──────────────────────────────────────────────

  // 1. サマリーカード
  Widget _buildSummaryCard(BuildContext context) {
    final total = kAmountFormat.format(summary.totalExpense);
    final currency = summary.byCurrency.isNotEmpty
        ? summary.byCurrency.first['currency'] as String? ?? 'JPY'
        : 'JPY';

    return Card(
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
            // 月選択ナビゲーション
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
                IconButton(
                  onPressed: onPrev,
                  icon: const Icon(Icons.chevron_left),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
                Text(
                  '${selectedMonth.year}年 ${selectedMonth.month}月',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 合計金額
            Text('支出合計',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children:[
                Text(
                  currency,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  total,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '計 ${summary.count} 件',
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
    );
  }

  // 2. 円グラフカード
  Widget _buildChartCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: SizedBox(
          height: 240, // グラフの高さを固定して安定させる
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
                final pct =
                    summary.totalExpense > 0 ? cat.total / summary.totalExpense * 100 : 0.0;
                return PieChartSectionData(
                  color: color,
                  value: cat.total,
                  // タッチされたら少し大きくする（アニメーション効果）
                  radius: isTouched ? 75 : 60,
                  title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
                  titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                );
              }).toList(),
              centerSpaceRadius: 55, // ドーナツの穴の大きさ
              sectionsSpace: 3,      // セクション間の隙間
            ),
          ),
        ),
      ),
    );
  }

  // 3. カテゴリ別リストカード
  Widget _buildCategoryListCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: summary.byCategory.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
        itemBuilder: (ctx, i) {
          final cat = summary.byCategory[i];
          final color = kCategoryColors[i % kCategoryColors.length];
          final emoji = kCategoryEmoji[cat.name] ?? '📦';
          final catAmount = kAmountFormat.format(cat.total);
          final pct = summary.totalExpense > 0 ? cat.total / summary.totalExpense * 100 : 0.0;
          final isTouched = i == touchedIndex;

          return InkWell(
            onTap: () => onTouch(isTouched ? -1 : i), // リストタップでグラフと連動
            borderRadius: BorderRadius.circular(i == 0
                ? 20 // 最初のアイテムは上部角丸
                : i == summary.byCategory.length - 1
                    ? 20 // 最後のアイテムは下部角丸
                    : 0),
            child: Container(
              // タッチされたアイテムの背景色を僅かに変える
              color: isTouched ? color.withOpacity(0.05) : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children:[
                  // 左側：アイコンバッジ
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 16),
                  
                  // 中央：カテゴリ名と件数
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        Text(
                          cat.name,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${cat.count}件',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  
                  // 右側：金額とパーセンテージ（縦並びでスタイリッシュに）
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children:[
                      Text(
                        '¥$catAmount',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: TextStyle(
                            color: isTouched ? color : Colors.grey[500],
                            fontSize: 12,
                            fontWeight: isTouched
                                ? FontWeight.bold
                                : FontWeight.normal),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}