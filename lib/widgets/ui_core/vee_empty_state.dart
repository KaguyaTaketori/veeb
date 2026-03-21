// lib/widgets/ui_core/vee_empty_state.dart
//
// VeeEmptyState — 空状态占位组件
// Phase 2 更新：使用 VeeTokens 间距，TextTheme 文字样式

import 'package:flutter/material.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

class VeeEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// 图标颜色，默认灰色
  final Color? iconColor;

  const VeeEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: VeeTokens.formPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size:  VeeTokens.iconHero,
              color: iconColor ?? Colors.grey.shade300,
            ),
            const SizedBox(height: VeeTokens.spacingMd),
            Text(
              title,
              style: context.veeText.cardTitle.copyWith(
                color: VeeTokens.textSecondaryVal,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: VeeTokens.spacingXs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: context.veeText.caption.copyWith(
                  color: VeeTokens.textPlaceholderVal,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: VeeTokens.spacingLg),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}