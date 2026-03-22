// lib/widgets/ui_core/vee_month_selector.dart
//
// VeeMonthSelector — 统一月份导航组件（UI 层）
//
// 变更说明（Bug Fix #1）：
//   - 新增 onMonthSelected: ValueChanged<DateTime>? 回调参数
//   - 修复 _showMonthPicker：picked 结果现在会通过 onMonthSelected 传出，
//     而不是静默丢弃
//   - VeeMonthSelectorCard 同步新增 onMonthSelected 参数并向下透传
//   - 其余逻辑、样式与原版完全一致

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

  /// 用户通过日期选择器选中某月后的回调。
  /// 传入值已规范化为该月第一天（day=1，时分秒为0）。
  /// 若为 null，则点击月份标题不弹出选择器。
  final ValueChanged<DateTime>? onMonthSelected;

  const VeeMonthSelector({
    super.key,
    required this.month,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
    this.dateFormat,
    this.onMonthSelected, // ← 新增，可选
  });

  @override
  Widget build(BuildContext context) {
    final fmt = dateFormat ?? DateFormat.yMMMM();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ── 上一月 ────────────────────────────────────────────────────────
        _NavButton(icon: Icons.chevron_left, onTap: onPrev, enabled: true),

        // ── 月份标题（onMonthSelected 不为 null 时可点击弹出 DatePicker）──
        GestureDetector(
          // 仅在父层关心选择结果时才响应点击，否则为纯展示
          onTap: onMonthSelected != null
              ? () => _showMonthPicker(context)
              : null,
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
                // 当可点击时，用主色给用户一个微妙的视觉提示
                color: onMonthSelected != null
                    ? VeeTokens.brandPrimaryDark
                    : null,
                decoration: onMonthSelected != null
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: VeeTokens.brandPrimaryDark.withOpacity(0.35),
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

  /// 弹出月份选择器，将结果规范化后通过 [onMonthSelected] 传出。
  Future<void> _showMonthPicker(BuildContext context) async {
    // onMonthSelected 为 null 时不应走到这里，但做防御检查
    if (onMonthSelected == null) return;

    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: month,
      firstDate: DateTime(2020),
      // 限制不能选未来月份
      lastDate: DateTime(now.year, now.month),
      helpText: '选择月份',
      fieldLabelText: '年/月',
    );

    // picked 为 null 表示用户取消，直接返回
    if (picked == null) return;

    // 规范化为该月第一天，保证调用方收到一致的值
    final normalized = DateTime(picked.year, picked.month);

    // 确保 context 仍然挂载（async gap 后的安全检查）
    if (!context.mounted) return;

    onMonthSelected!(normalized);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 导航按钮（上一月 / 下一月）
// ─────────────────────────────────────────────────────────────────────────────

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
            width: VeeTokens.touchMin,
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
// ─────────────────────────────────────────────────────────────────────────────
//
// 变更说明：
//   - 新增 onMonthSelected 参数，透传给内部的 VeeMonthSelector
//
// 使用示例（StatsScreen / TransactionsScreen）：
//
//   VeeMonthSelectorCard(
//     month:            selectedMonth,
//     canGoNext:        !isCurrentMonth,
//     onPrev:           prevMonth,
//     onNext:           nextMonth,
//     onMonthSelected:  (m) {
//       setState(() => selectedMonth = m);
//       onMonthChanged();
//     },
//     child: ...,
//   )

class VeeMonthSelectorCard extends StatelessWidget {
  final DateTime month;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  /// 用户通过弹窗选中某月后的回调（可选）。
  /// 传入值已规范化为该月第一天。
  final ValueChanged<DateTime>? onMonthSelected;

  /// 月份导航下方的内容区域
  final Widget child;

  const VeeMonthSelectorCard({
    super.key,
    required this.month,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
    required this.child,
    this.onMonthSelected, // ← 新增，可选，向下透传
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
              month: month,
              canGoNext: canGoNext,
              onPrev: onPrev,
              onNext: onNext,
              onMonthSelected: onMonthSelected, // ← 透传
            ),
            child,
          ],
        ),
      ),
    );
  }
}
