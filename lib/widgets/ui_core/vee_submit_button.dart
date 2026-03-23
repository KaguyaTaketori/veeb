// lib/widgets/ui_core/vee_submit_button.dart
//
// VeeSubmitButton — 提交/CTA 按钮
// Phase 2 更新：
//   - 尺寸 / 圆角继承全局 FilledButtonTheme（Phase 1 已注入）
//   - 使用 VeeTokens.buttonHeight 统一按钮高度
//   - isLoading 时锁定交互并展示 VeeButtonSpinner（替换原内联 SizedBox）

import 'package:flutter/material.dart';
import 'vee_button_spinner.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

class VeeSubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;

  const VeeSubmitButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = isLoading
        ? const VeeButtonSpinner() // ← 替换原 SizedBox + CircularProgressIndicator
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: VeeTokens.iconMd),
                const SizedBox(width: VeeTokens.spacingXs),
              ],
              Text(label, style: context.veeText.buttonLabel),
            ],
          );

    return SizedBox(
      width: double.infinity,
      height: VeeTokens.buttonHeight,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              child: content,
            )
          : FilledButton(
              onPressed: isLoading ? null : onPressed,
              child: content,
            ),
    );
  }
}
