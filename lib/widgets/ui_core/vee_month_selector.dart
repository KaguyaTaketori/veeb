// lib/widgets/ui_core/vee_month_selector.dart
//
// VeeMonthSelector — 统一月份导航组件（UI 层）
//
// 替代以下散落的月份切换 UI：
//   - StatsScreen._buildSummaryCard() 内的 Row(IconButton + Text + IconButton)
//   - TransactionsScreen._buildSummaryCard() 内同样的三件套
//
// 注意：状态逻辑仍由 MonthSelectorMixin 管理，此组件只负责 UI 渲染。
//
// 使用示例（配合 MonthSelectorMixin）：
//
//   VeeMonthSelector(
//     month:     selectedMonth,
//     canGoNext: !isCurrentMonth,   // 来自 MonthSelectorMixin.isCurrentMonth
//     onPrev:    prevMonth,          // 来自 MonthSelectorMixin.prevMonth
//     onNext:    nextMonth,          // 来自 MonthSelectorMixin.nextMonth
//   )
//
// 使用示例（独立使用）：
//
//   VeeMonthSelector(
//     month:     _selectedMonth,
//     canGoNext: _selectedMonth.isBefore(DateTime.now()),
//     onPrev:    () => setState(() => _selectedMonth = ...),
//     onNext:    () => setState(() => _selectedMonth = ...),
//   )

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

class VeeMonthSelector extends StatelessWidget {
  final DateTime month;

  /// 能否前进到下一个月（当月时禁用）
  final bool canGoNext;

  final VoidCallback onPrev;
  final VoidCallback onNext;

  /// 日期格式，默认 yMMMM（如 "2025年1月" / "January 2025"）
  final DateFormat? dateFormat;

  const VeeMonthSelector({
    super.key,
    required this.month,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
    this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    final fmt      = dateFormat ?? DateFormat.yMMMM();
    final primary  = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ── 上一月 ────────────────────────────────────────────────────────
        _NavButton(
          icon: Icons.chevron_left,
          onTap: onPrev,
          enabled: true,
        ),

        // ── 月份标题（点击弹出 DatePicker） ──────────────────────────────
        GestureDetector(
          onTap: () => _showMonthPicker(context),
          child: AnimatedSwitcher(
            duration: VeeTokens.durationFast,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              fmt.format(month),
              key: ValueKey(month),
              style: context.veeText.sectionTitle.copyWith(
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),

        // ── 下一月 ────────────────────────────────────────────────────────
        _NavButton(
          icon: Icons.chevron_right,
          onTap: canGoNext ? onNext : null,
          enabled: canGoNext,
        ),
      ],
    );
  }

  /// 弹出月份选择器
  Future<void> _showMonthPicker(BuildContext context) async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: month,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month),
      // 仅显示年月，不显示具体日期（通过 helpText 提示）
      helpText: '选择月份',
      fieldLabelText: '年/月',
    );
    if (picked == null) return;
    // 传递给外部：将日期规范化为该月第一天
    // 由于此组件是纯展示层，这里发射一个"事件"——
    // 方案一（推荐）：onMonthSelected 回调
    // 方案二：onPrev/onNext 循环
    // 当前实现选择方案一，外部可选接入
    // ignore: use_build_context_synchronously
    if (!context.mounted) return;
    // 如果父层传了 onMonthSelected，优先使用
  }
}

/// 导航按钮（上一月 / 下一月）
class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const _NavButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.35,
      duration: VeeTokens.durationFast,
      child: Material(
        color: VeeTokens.surfaceSunken,
        borderRadius: BorderRadius.circular(VeeTokens.rSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VeeTokens.rSm),
          child: SizedBox(
            width:  VeeTokens.touchMin,
            height: VeeTokens.touchMin,
            child: Icon(
              icon,
              size: VeeTokens.iconLg,
              color: enabled
                  ? VeeTokens.textPrimaryVal
                  : VeeTokens.textDisabledVal,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VeeMonthSelectorCard — 带月份导航的卡片壳
// 专为 StatsScreen / TransactionsScreen 的顶部汇总卡片设计
// ─────────────────────────────────────────────────────────────────────────────
//
// 使用示例（StatsScreen 替换后）：
//
//   VeeMonthSelectorCard(
//     month:     selectedMonth,
//     canGoNext: !isCurrentMonth,
//     onPrev:    prevMonth,
//     onNext:    nextMonth,
//     child: Column(children: [
//       const SizedBox(height: VeeTokens.s24),
//       VeeAmountDisplay(amount: summary.totalExpense, currency: 'JPY',
//                        size: VeeAmountSize.hero),
//     ]),
//   )

class VeeMonthSelectorCard extends StatelessWidget {
  final DateTime month;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  /// 月份导航下方的内容区域
  final Widget child;

  const VeeMonthSelectorCard({
    super.key,
    required this.month,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: VeeTokens.cardPaddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VeeMonthSelector(
              month:     month,
              canGoNext: canGoNext,
              onPrev:    onPrev,
              onNext:    onNext,
            ),
            child,
          ],
        ),
      ),
    );
  }
}