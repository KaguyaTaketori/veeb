// lib/widgets/ui_core/vee_month_selector.dart
//
// 变更说明（引入 flutter_animate）：
//   - AnimatedSwitcher + 14行 transitionBuilder 样板
//     → Text(...).animate(key: ValueKey(month)).fadeIn().slideY()
//   - 效果等价：月份切换时新文字淡入 + 从下方轻微滑入

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

class VeeMonthSelector extends StatelessWidget {
  final DateTime month;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final DateFormat? dateFormat;
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

          // ── flutter_animate 替代 AnimatedSwitcher ──────────────────────
          // key: ValueKey(month) → 月份变化时触发重新动画
          // .fadeIn()  → 替代 FadeTransition
          // .slideY()  → 替代 SlideTransition(Offset(0, 0.15) → Offset.zero)
          child:
              Text(
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
                      decorationColor: VeeTokens.brandPrimaryDark.withOpacity(
                        0.35,
                      ),
                    ),
                  )
                  .animate(key: ValueKey(month))
                  .fadeIn(
                    duration: VeeTokens.durationFast,
                    curve: Curves.easeOut,
                  )
                  .slideY(
                    begin: 0.15,
                    end: 0,
                    duration: VeeTokens.durationFast,
                    curve: Curves.easeOut,
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
    final lastDate = DateTime(now.year, now.month + 1, 0);
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
    final normalized = DateTime(picked.year, picked.month);
    if (!context.mounted) return;
    onMonthSelected!(normalized);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 导航按钮（与原版相同）
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
// VeeMonthSelectorCard（与原版相同）
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
