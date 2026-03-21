// lib/screens/stats/stats_screen.dart
//
// 变更说明（Bug Fix #1 调用侧）：
//   - VeeMonthSelectorCard 新增 onMonthSelected 参数
//   - 用户通过弹窗选择月份后，正确更新 selectedMonth 并触发数据加载
//   - 其余逻辑、样式与原版完全一致

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../constants/categories.dart';
import '../../l10n/app_localizations.dart';
import '../../mixin/month_selector_mixin.dart';
import '../../models/transaction.dart' show MonthlyStat, CategoryStat;
import '../../providers/stats_provider.dart';
import '../../widgets/ui_core/vee_amount_display.dart';
import '../../widgets/ui_core/vee_empty_state.dart';
import '../../widgets/ui_core/vee_month_selector.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_text_styles.dart';

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
    setState(() => _touchedIndex = -1);
  }

  // ── Bug Fix #1：弹窗选月的处理 ──────────────────────────────────────────
  //
  // 原来 _showMonthPicker 拿到 picked 后什么都没做。
  // 现在由 VeeMonthSelectorCard.onMonthSelected 回调触发，
  // 在这里统一更新 selectedMonth 并调用 onMonthChanged()。

  void _onMonthSelected(DateTime picked) {
    // picked 已由 VeeMonthSelector 规范化为该月第一天
    if (picked.year == selectedMonth.year &&
        picked.month == selectedMonth.month) {
      return; // 同月无需刷新
    }
    setState(() => selectedMonth = picked);
    onMonthChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.stats)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: VeeTokens.maxContentWidth,
          ),
          child: _buildBody(context, state, l10n),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    StatsState state,
    AppLocalizations l10n,
  ) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return VeeEmptyState(
        icon: Icons.error_outline,
        title: state.error!,
        iconColor: VeeTokens.error,
        actionLabel: l10n.retry,
        onAction: () => ref.read(statsProvider.notifier).load(selectedMonth),
      );
    }
    if (state.summary == null) {
      return VeeEmptyState(icon: Icons.bar_chart, title: l10n.noData);
    }

    final summary = state.summary!;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: VeeTokens.s16,
        vertical: VeeTokens.s8,
      ),
      children: [
        _buildSummaryCard(context, summary, l10n),
        const SizedBox(height: VeeTokens.spacingMd),

        if (summary.byCategory.isNotEmpty) ...[
          _buildChartCard(context, summary),
          const SizedBox(height: VeeTokens.spacingMd),
          _buildCategoryListCard(context, summary, l10n),
          const SizedBox(height: VeeTokens.spacingXxl),
        ] else ...[
          const SizedBox(height: VeeTokens.spacingXxl),
          VeeEmptyState(
            icon: Icons.receipt_long_outlined,
            title: l10n.noTransactions,
          ),
        ],
      ],
    );
  }

  // ── 1. 汇总卡 ─────────────────────────────────────────────────────────────

  Widget _buildSummaryCard(
    BuildContext context,
    MonthlyStat summary,
    AppLocalizations l10n,
  ) {
    final currency = summary.byCurrency.isNotEmpty
        ? summary.byCurrency.first['currency'] as String? ?? 'JPY'
        : 'JPY';

    return VeeMonthSelectorCard(
      month: selectedMonth,
      canGoNext: !isCurrentMonth,
      onPrev: prevMonth,
      onNext: nextMonth,
      // ↓ Bug Fix #1：接入弹窗选月回调
      onMonthSelected: _onMonthSelected,
      child: Column(
        children: [
          const SizedBox(height: VeeTokens.s24),

          Text(
            l10n.totalExpense,
            style: context.veeText.caption.copyWith(
              color: VeeTokens.textSecondaryVal,
            ),
          ),
          const SizedBox(height: VeeTokens.s4),
          VeeAmountDisplay(
            amount: summary.totalExpense,
            currency: currency,
            size: VeeAmountSize.hero,
          ),
          const SizedBox(height: VeeTokens.spacingXs),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VeeTokens.s12,
              vertical: VeeTokens.s4,
            ),
            decoration: BoxDecoration(
              color: VeeTokens.selectedTint(
                Theme.of(context).colorScheme.primary,
              ),
              borderRadius: BorderRadius.circular(VeeTokens.rFull),
            ),
            child: Text(
              l10n.records(summary.count),
              style: context.veeText.micro.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. 饼图卡 ─────────────────────────────────────────────────────────────

  Widget _buildChartCard(BuildContext context, MonthlyStat summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: VeeTokens.s32,
          horizontal: VeeTokens.s16,
        ),
        child: SizedBox(
          height: 240,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    _touchedIndex = response?.touchedSection != null
                        ? response!.touchedSection!.touchedSectionIndex
                        : -1;
                  });
                },
              ),
              sections: summary.byCategory.asMap().entries.map((e) {
                final i = e.key;
                final cat = e.value;
                final isTouched = i == _touchedIndex;
                final color = kCategoryColors[i % kCategoryColors.length];
                final pct = summary.totalExpense > 0
                    ? cat.total / summary.totalExpense * 100
                    : 0.0;
                return PieChartSectionData(
                  color: color,
                  value: cat.total,
                  radius: isTouched ? 75 : 60,
                  title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              }).toList(),
              centerSpaceRadius: 55,
              sectionsSpace: 3,
            ),
          ),
        ),
      ),
    );
  }

  // ── 3. 分类列表卡 ─────────────────────────────────────────────────────────

  Widget _buildCategoryListCard(
    BuildContext context,
    MonthlyStat summary,
    AppLocalizations l10n,
  ) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: summary.byCategory.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: VeeTokens.dividerIndentLg),
        itemBuilder: (ctx, i) {
          final cat = summary.byCategory[i];
          final color = kCategoryColors[i % kCategoryColors.length];
          final emoji = kCategoryEmoji[cat.name] ?? '📦';
          final pct = summary.totalExpense > 0
              ? cat.total / summary.totalExpense * 100
              : 0.0;
          final isTouched = i == _touchedIndex;

          return _CategoryRow(
            cat: cat,
            color: color,
            emoji: emoji,
            pct: pct,
            isTouched: isTouched,
            isFirst: i == 0,
            isLast: i == summary.byCategory.length - 1,
            onTap: () => setState(() => _touchedIndex = isTouched ? -1 : i),
            l10n: l10n,
          );
        },
      ),
    );
  }
}

// ── 分类列表行 ─────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final CategoryStat cat;
  final Color color;
  final String emoji;
  final double pct;
  final bool isTouched;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  const _CategoryRow({
    required this.cat,
    required this.color,
    required this.emoji,
    required this.pct,
    required this.isTouched,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius inkRadius;
    if (isFirst && isLast) {
      inkRadius = VeeTokens.cardBorderRadiusLg;
    } else if (isFirst) {
      inkRadius = const BorderRadius.vertical(
        top: Radius.circular(VeeTokens.rXl),
      );
    } else if (isLast) {
      inkRadius = const BorderRadius.vertical(
        bottom: Radius.circular(VeeTokens.rXl),
      );
    } else {
      inkRadius = BorderRadius.zero;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: inkRadius,
      child: AnimatedContainer(
        duration: VeeTokens.durationFast,
        color: isTouched ? VeeTokens.hoverTint(color) : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: VeeTokens.s16,
          vertical: VeeTokens.s16,
        ),
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
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: VeeTokens.spacingMd),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.name, style: context.veeText.cardTitle),
                  const SizedBox(height: VeeTokens.s2),
                  Text(
                    l10n.records(cat.count),
                    style: context.veeText.caption.copyWith(
                      color: VeeTokens.textSecondaryVal,
                    ),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                VeeAmountDisplay(
                  amount: cat.total,
                  currency: 'JPY',
                  size: VeeAmountSize.small,
                ),
                const SizedBox(height: VeeTokens.s2),
                Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: context.veeText.caption.copyWith(
                    color: isTouched ? color : VeeTokens.textSecondaryVal,
                    fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
