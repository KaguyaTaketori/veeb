import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

class VeeExpandableSection extends StatefulWidget {
  final String label;
  final IconData icon;
  final Widget child;

  /// 折叠状态时显示的数量角标（为 0 或 null 时不显示）
  final int? badgeCount;

  /// 初始状态是否展开，默认 false（收起）
  final bool initiallyExpanded;

  const VeeExpandableSection({
    super.key,
    required this.label,
    required this.icon,
    required this.child,
    this.badgeCount,
    this.initiallyExpanded = false,
  });

  @override
  State<VeeExpandableSection> createState() => _VeeExpandableSectionState();
}

// ─────────────────────────────────────────────────────────────────────────────
// 原版需要 SingleTickerProviderStateMixin + AnimationController + CurvedAnimation。
// flutter_animate 的 animate(target:) 接管所有时序，State 只需一个 bool。
// ─────────────────────────────────────────────────────────────────────────────

class _VeeExpandableSectionState extends State<VeeExpandableSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final showBadge =
        !_expanded && widget.badgeCount != null && widget.badgeCount! > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header（整行可点击）──────────────────────────────────────────
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(VeeTokens.rMd),
          splashColor: VeeTokens.selectedTint(primary),
          highlightColor: VeeTokens.hoverTint(primary),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: VeeTokens.s12,
              horizontal: VeeTokens.s4,
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: VeeTokens.iconMd,
                  color: VeeTokens.textSecondaryVal,
                ),
                const SizedBox(width: VeeTokens.spacingXs),
                Text(
                  widget.label,
                  style: context.veeText.caption.copyWith(
                    color: VeeTokens.textSecondaryVal,
                  ),
                ),

                // 角标
                if (showBadge) ...[
                  const SizedBox(width: VeeTokens.spacingXxs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VeeTokens.s6,
                      vertical: VeeTokens.s2,
                    ),
                    decoration: BoxDecoration(
                      color: VeeTokens.selectedTint(primary),
                      borderRadius: BorderRadius.circular(VeeTokens.rFull),
                    ),
                    child: Text(
                      '${widget.badgeCount}',
                      style: context.veeText.micro.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // ── Chevron：用 flutter_animate 替代 AnimatedRotation ──
                // target: 0.0 → 旋转反转回 0（收起）
                // target: 1.0 → 旋转到 0.5 圈（180°，展开）
                Icon(
                      Icons.keyboard_arrow_down,
                      size: VeeTokens.iconMd,
                      color: VeeTokens.textPlaceholderVal,
                    )
                    .animate(target: _expanded ? 1.0 : 0.0)
                    .rotate(
                      begin: 0,
                      end: 0.5,
                      duration: VeeTokens.durationNormal,
                      curve: Curves.easeInOut,
                    ),
              ],
            ),
          ),
        ),

        // ── 展开内容：用 flutter_animate 替代 SizeTransition + FadeTransition ──
        // target: 1.0 → fadeIn + expand（展开到自然高度）
        // target: 0.0 → fadeOut + collapse（收缩到 0 高度）
        widget.child
            .animate(target: _expanded ? 1.0 : 0.0)
            .fadeIn(duration: VeeTokens.durationNormal, curve: Curves.easeInOut)
            .slideY(
              begin: -0.1,
              end: 0,
              duration: VeeTokens.durationNormal,
              curve: Curves.easeInOut,
            ),
      ],
    );
  }
}
