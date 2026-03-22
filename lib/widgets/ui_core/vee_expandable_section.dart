// lib/widgets/ui_core/vee_expandable_section.dart
//
// VeeExpandableSection — 可展开/收起的区块容器
//
// 设计说明：
//   - header 整行可点击，带 chevron 旋转动画
//   - 折叠时可在 header 右侧显示内容数量角标（badgeCount）
//   - 展开/收起使用 SizeTransition + FadeTransition 双重动画
//   - initiallyExpanded 支持默认展开状态
//
// 用法示例：
//
//   VeeExpandableSection(
//     label: '更多选项',
//     icon: Icons.tune_outlined,
//     badgeCount: filledCount,      // 有内容时角标显示数量
//     child: Column(children: [...]),
//   )

import 'package:flutter/material.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

class VeeExpandableSection extends StatefulWidget {
  final String label;
  final IconData icon;
  final Widget child;

  /// 折叠状态时显示的数量角标。
  /// 为 0 或 null 时不显示角标。
  final int? badgeCount;

  /// 初始状态是否展开，默认 false（收起）。
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

class _VeeExpandableSectionState extends State<VeeExpandableSection>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController _ctrl;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _ctrl = AnimationController(
      vsync: this,
      duration: VeeTokens.durationNormal,
      value: _expanded ? 1.0 : 0.0,
    );
    _curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

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
                // 图标
                Icon(
                  widget.icon,
                  size: VeeTokens.iconMd,
                  color: VeeTokens.textSecondaryVal,
                ),
                const SizedBox(width: VeeTokens.spacingXs),

                // 标签
                Text(
                  widget.label,
                  style: context.veeText.caption.copyWith(
                    color: VeeTokens.textSecondaryVal,
                  ),
                ),

                // 角标（折叠时显示已填内容数量）
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

                // Chevron 旋转动画
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0.0,
                  duration: VeeTokens.durationNormal,
                  curve: Curves.easeInOut,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: VeeTokens.iconMd,
                    color: VeeTokens.textPlaceholderVal,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── 展开内容（双重动画：高度 + 透明度）─────────────────────────
        SizeTransition(
          sizeFactor: _curve,
          axisAlignment: -1,
          child: FadeTransition(opacity: _curve, child: widget.child),
        ),
      ],
    );
  }
}
