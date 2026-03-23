// lib/widgets/ui_core/vee_monthly_trend_card.dart
//
// VeeMonthlyTrendCard — 月度收支趋势卡
//
// 展示最近 N 个月的支出 / 收入折线图（默认 6 个月）。
// 数据源：monthlyTrendProvider（自动区分已登录 / Guest 模式）。
//
// 用法：
//   VeeMonthlyTrendCard(anchor: selectedMonth)
//
// 可选参数：
//   months  — 展示月数，默认 6
//   showIncome — 是否叠加收入线，默认 true

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/monthly_trend_provider.dart';
import '../../utils/currency.dart';
import 'vee_card.dart';
import 'vee_skeleton_card.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

class VeeMonthlyTrendCard extends ConsumerStatefulWidget {
  final DateTime anchor;
  final int months;
  final bool showIncome;

  const VeeMonthlyTrendCard({
    super.key,
    required this.anchor,
    this.months = 6,
    this.showIncome = true,
  });

  @override
  ConsumerState<VeeMonthlyTrendCard> createState() =>
      _VeeMonthlyTrendCardState();
}

class _VeeMonthlyTrendCardState extends ConsumerState<VeeMonthlyTrendCard> {
  // 触摸高亮月份索引（-1 = 无）
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final key = (anchor: widget.anchor, months: widget.months);
    final async = ref.watch(monthlyTrendProvider(key));

    return async.when(
      loading: () => VeeSkeletonCard.card(),
      error: (_, __) => const SizedBox.shrink(),
      data: (points) => _buildCard(context, points),
    );
  }

  Widget _buildCard(BuildContext context, List<MonthPoint> points) {
    if (points.every((p) => p.expense == 0 && p.income == 0)) {
      return const SizedBox.shrink(); // 全空数据不渲染
    }

    final primary = Theme.of(context).colorScheme.primary;

    return VeeCard(
      padding: const EdgeInsets.fromLTRB(
        VeeTokens.s16,
        VeeTokens.s16,
        VeeTokens.s8,
        VeeTokens.s12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 标题行 ─────────────────────────────────────────────────────
          Row(
            children: [
              Text('趋势', style: context.veeText.cardTitle),
              const Spacer(),
              // 图例
              _LegendDot(color: VeeTokens.error, label: '支出'),
              if (widget.showIncome) ...[
                const SizedBox(width: VeeTokens.spacingXs),
                _LegendDot(color: VeeTokens.success, label: '收入'),
              ],
            ],
          ),
          const SizedBox(height: VeeTokens.spacingMd),

          // ── 折线图 ─────────────────────────────────────────────────────
          SizedBox(
            height: 130,
            child: LineChart(
              _buildChartData(context, points),
              duration: VeeTokens.durationNormal,
            ),
          ),

          // ── 触摸提示标签 ───────────────────────────────────────────────
          if (_touchedIndex >= 0 && _touchedIndex < points.length) ...[
            const SizedBox(height: VeeTokens.spacingXs),
            _buildTooltip(context, points[_touchedIndex]),
          ],
        ],
      ),
    );
  }

  // ── 图表数据 ────────────────────────────────────────────────────────────

  LineChartData _buildChartData(BuildContext context, List<MonthPoint> points) {
    final maxY = points
        .map(
          (p) => widget.showIncome
              ? [p.expense, p.income].reduce((a, b) => a > b ? a : b)
              : p.expense,
        )
        .reduce((a, b) => a > b ? a : b);

    final topY = maxY <= 0 ? 10000.0 : maxY * 1.25;

    // 支出数据点
    final expenseSpots = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.expense))
        .toList();

    // 收入数据点
    final incomeSpots = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.income))
        .toList();

    return LineChartData(
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      minY: 0,
      maxY: topY,

      // 触摸处理
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => Colors.transparent,
          tooltipBorderRadius: BorderRadius.zero,
          getTooltipItems: (spots) => List.filled(spots.length, null),
        ),
        touchCallback: (event, response) {
          final idx = response?.lineBarSpots?.firstOrNull?.spotIndex;
          if (event is FlTapUpEvent || event is FlPanEndEvent) {
            setState(() => _touchedIndex = -1);
          } else if (idx != null) {
            setState(() => _touchedIndex = idx);
          }
        },
      ),

      // 网格
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: topY / 4,
        getDrawingHorizontalLine: (v) => FlLine(
          color: VeeTokens.borderColor,
          strokeWidth: 0.5,
          dashArray: [4, 4],
        ),
      ),

      // 轴
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= points.length) {
                return const SizedBox.shrink();
              }
              return Text(
                points[idx].label,
                style: TextStyle(
                  fontSize: 10,
                  color: idx == _touchedIndex
                      ? Theme.of(context).colorScheme.primary
                      : VeeTokens.textPlaceholderVal,
                ),
              );
            },
          ),
        ),
      ),

      // 边框
      borderData: FlBorderData(show: false),

      // 折线
      lineBarsData: [
        // 支出线（红色）
        LineChartBarData(
          spots: expenseSpots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: VeeTokens.error,
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, _) => spot.x.toInt() == _touchedIndex,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 4,
              color: VeeTokens.error,
              strokeWidth: 0,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                VeeTokens.error.withOpacity(0.12),
                VeeTokens.error.withOpacity(0.0),
              ],
            ),
          ),
        ),

        // 收入线（绿色，可选）
        if (widget.showIncome)
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: VeeTokens.success,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, _) => spot.x.toInt() == _touchedIndex,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 4,
                color: VeeTokens.success,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(show: false),
          ),
      ],
    );
  }

  // ── 触摸提示 ─────────────────────────────────────────────────────────────

  Widget _buildTooltip(BuildContext context, MonthPoint p) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${p.year}/${p.month.toString().padLeft(2, '0')}  ',
          style: context.veeText.micro.copyWith(
            color: VeeTokens.textSecondaryVal,
          ),
        ),
        Text(
          '支 ¥${formatAmount(p.expense, 'JPY')}',
          style: context.veeText.micro.copyWith(
            color: VeeTokens.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (widget.showIncome) ...[
          const SizedBox(width: VeeTokens.spacingXs),
          Text(
            '收 ¥${formatAmount(p.income, 'JPY')}',
            style: context.veeText.micro.copyWith(
              color: VeeTokens.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 图例点
// ─────────────────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: VeeTokens.spacingXxs),
        Text(
          label,
          style: context.veeText.micro.copyWith(
            color: VeeTokens.textSecondaryVal,
          ),
        ),
      ],
    );
  }
}
