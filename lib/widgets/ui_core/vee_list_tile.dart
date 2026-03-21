// lib/widgets/ui_core/vee_list_tile.dart
//
// VeeListTile — 通用列表行
// Phase 2 更新：
//   - 使用 VeeTokens 间距常量（替代硬编码 70/52/16 等数字）
//   - leading 图标宽度对齐常量 dividerIndentStd
//   - 文字样式通过 TextTheme 引用

import 'package:flutter/material.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

class VeeListTile extends StatelessWidget {
  final IconData? leadingIcon;
  final String title;

  /// 右侧文字值（如 "未设置"）
  final String? valueText;

  /// 自定义右侧控件（如 Switch、箭头图标）
  /// 若设置此参数，valueText 和 showArrow 均无效
  final Widget? customTrailing;

  final VoidCallback? onTap;

  /// 是否在右侧显示 chevron_right 箭头
  /// 仅在 onTap != null 且 customTrailing == null 时生效
  final bool showArrow;

  /// 标签列宽（固定宽度保证多行对齐）
  static const double _labelWidth = 72.0;

  const VeeListTile({
    super.key,
    this.leadingIcon,
    required this.title,
    this.valueText,
    this.customTrailing,
    this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: VeeTokens.tilePadding,
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size:  VeeTokens.iconMd,
                color: VeeTokens.textPlaceholderVal,
              ),
              const SizedBox(width: VeeTokens.spacingSm),
            ],
            SizedBox(
              width: _labelWidth,
              child: Text(
                title,
                style: context.veeText.bodyDefault.copyWith(
                  color: VeeTokens.textSecondaryVal,
                ),
              ),
            ),
            Expanded(
              child: customTrailing ??
                  Text(
                    valueText ?? '',
                    style: context.veeText.cardTitle,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
            ),
            if (onTap != null && showArrow && customTrailing == null) ...[
              const SizedBox(width: VeeTokens.spacingXxs),
              Icon(
                Icons.chevron_right,
                color: VeeTokens.textPlaceholderVal,
                size:  VeeTokens.iconMd,
              ),
            ],
          ],
        ),
      ),
    );
  }
}