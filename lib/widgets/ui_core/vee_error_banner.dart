// lib/widgets/ui_core/vee_error_banner.dart
//
// Phase 2 更新：使用 VeeTokens 间距，TextTheme 文字样式

import 'package:flutter/material.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

class VeeErrorBanner extends StatelessWidget {
  final String message;
  final EdgeInsetsGeometry margin;

  const VeeErrorBanner({
    super.key,
    required this.message,
    this.margin = const EdgeInsets.only(bottom: VeeTokens.spacingMd),
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(VeeTokens.spacingSm),
      decoration: BoxDecoration(
        color: VeeTokens.selectedTint(VeeTokens.error),
        borderRadius: BorderRadius.circular(VeeTokens.rMd),
        border: Border.all(
          color: VeeTokens.error.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size:  VeeTokens.iconSm,
            color: VeeTokens.error,
          ),
          const SizedBox(width: VeeTokens.spacingXs),
          Expanded(
            child: Text(
              message,
              style: context.veeText.caption.copyWith(
                color: VeeTokens.error,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}