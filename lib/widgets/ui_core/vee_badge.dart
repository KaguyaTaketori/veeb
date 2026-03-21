// lib/widgets/ui_core/vee_badge.dart
//
// VeeBadge — 通用状态标签 / 角标组件
//
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VeeBadge
//
// 用于：权限标签、角色标签、绑定状态、封禁状态等所有需要彩色 pill 的场景。
//
// 设计规范：
//   - 背景：selectedTint(color)  → 12% 透明度，软化的彩色背景
//   - 文字：color 本身（已经过 WCAG AA 校验，4.5:1 以上）
//   - 圆角：badgeBorderRadius (rXs = 6px)
//   - 内边距：badgePadding (h:8, v:2)
//   - 字号：labelSmall (11sp w500) — 仅适合非正文展示，WCAG 豁免小标签
//
// 用法示例：
//   VeeBadge(label: '管理员', color: Colors.orange)
//   VeeBadge(label: '已绑定', color: VeeTokens.success)
//   VeeBadge(label: '已封禁', color: VeeTokens.error)
//   VeeBadge(label: 'app_ocr', color: Theme.of(context).colorScheme.primary)
//
// ─────────────────────────────────────────────────────────────────────────────

class VeeBadge extends StatelessWidget {
  final String label;
  final Color color;

  /// 覆盖默认的 selectedTint 背景（少数特殊场景，如纯色背景 badge）
  final Color? backgroundColor;

  /// 覆盖默认文字颜色（默认与 color 相同）
  final Color? textColor;

  const VeeBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: VeeTokens.badgePadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? VeeTokens.selectedTint(color),
        borderRadius: VeeTokens.badgeBorderRadius,
      ),
      child: Text(
        label,
        style: context.veeText.micro.copyWith(
          color: textColor ?? color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
