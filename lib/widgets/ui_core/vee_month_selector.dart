// lib/widgets/ui_core/vee_month_selector.dart
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
    this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = dateFormat ?? DateFormat.yMMMM();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NavButton(icon: Icons.chevron_left, onTap: onPrev, enabled: true),

        GestureDetector(
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

        _NavButton(
          icon: Icons.chevron_right,
          onTap: canGoNext ? onNext : null,
          enabled: canGoNext,
        ),
      ],
    );
  }

  Future<void> _showMonthPicker(BuildContext context) async {
    if (onMonthSelected == null) return;

    final now = DateTime.now();

    // lastDate = 当月最后一天，避免 initialDate > lastDate 断言失败。
    // DateTime(y, m+1, 0) 是 m 月最后一天的 trick（day=0 会回退到上月最后一天）。
    final lastDate = DateTime(now.year, now.month + 1, 0);

    // initialDate 必须 ≤ lastDate；当 selectedMonth 是当月且 day > 1 时夹紧到 lastDate。
    final initialDate = month.isAfter(lastDate) ? lastDate : month;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: lastDate,
      helpText: '选择月份',
      fieldLabelText: '年/月',
    );

    if (picked == null) return;

    // 规范化为该月第一天
    final normalized = DateTime(picked.year, picked.month);

    if (!context.mounted) return;

    onMonthSelected!(normalized);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 导航按钮
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
// VeeMonthSelectorCard
// ─────────────────────────────────────────────────────────────────────────────

class VeeMonthSelectorCard extends StatelessWidget {
  final DateTime month;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime>? onMonthSelected;
  final Widget child;

  const VeeMonthSelectorCard({
    super.key,
    required this.month,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
    required this.child,
    this.onMonthSelected,
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
              onMonthSelected: onMonthSelected,
            ),
            child,
          ],
        ),
      ),
    );
  }
}
