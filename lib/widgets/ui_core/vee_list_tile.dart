import 'package:flutter/material.dart';
import 'vee_tokens.dart';

class VeeListTile extends StatelessWidget {
  final IconData? leadingIcon;
  final String title;
  final String? valueText; // 右侧文字（如："未设置"）
  final Widget? customTrailing; // 自定义右侧控件（如 Switch, 箭头）
  final VoidCallback? onTap;
  final bool showArrow; // 是否显示右侧小箭头

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
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VeeTokens.s16, vertical: 14),
        child: Row(
          children:[
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 20, color: VeeTokens.textPlaceholder),
              const SizedBox(width: VeeTokens.s12),
            ],
            SizedBox(
              width: 70, // 保持与你原设计一致的对齐宽度
              child: Text(title, style: TextStyle(color: VeeTokens.textSecondary, fontSize: 14)),
            ),
            Expanded(
              child: customTrailing ??
                  Text(
                    valueText ?? '',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
            ),
            if (onTap != null && showArrow && customTrailing == null) ...[
              const SizedBox(width: VeeTokens.s4),
              Icon(Icons.chevron_right, color: VeeTokens.textPlaceholder, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}