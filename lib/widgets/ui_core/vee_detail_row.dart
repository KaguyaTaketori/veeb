import 'package:flutter/material.dart';
import 'package:vee_app/widgets/ui_core/vee_text_styles.dart';
import 'package:vee_app/widgets/ui_core/vee_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VeeDetailRow
//
//
// 布局：
//   [icon 20px] [gap 12px] [label 固定宽度] [value Expanded 右对齐]
//
// 固定宽度 labelWidth 默认 70px，可通过参数覆盖（字段名较长时传 88 或 96）。
//
// 用法示例：
//   VeeDetailRow(
//     icon: Icons.store_outlined,
//     label: l10n.account,
//     value: result.merchant ?? l10n.notSet,
//   )
//   VeeDetailRow(
//     icon: Icons.calendar_today_outlined,
//     label: l10n.date,
//     value: '2025/03/15',
//   )
//
// ─────────────────────────────────────────────────────────────────────────────
class VeeDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  /// 标签列固定宽度，默认 70px，长字段传 88 / 96
  final double labelWidth;

  /// 值文字颜色，默认 textPrimaryVal
  final Color? valueColor;

  /// 值文字粗细，默认 w500
  final FontWeight valueWeight;

  /// 点击回调（可选，加上后整行变为可点击 InkWell）
  final VoidCallback? onTap;

  const VeeDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.labelWidth = 70.0,
    this.valueColor,
    this.valueWeight = FontWeight.w500,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: VeeTokens.tilePadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 图标 ────────────────────────────────────────────────────────
          Icon(icon, size: VeeTokens.iconMd, color: VeeTokens.textSecondaryVal),
          const SizedBox(width: VeeTokens.s12),

          // ── 标签（固定宽度，对齐多行） ──────────────────────────────────
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: context.veeText.caption.copyWith(
                color: VeeTokens.textSecondaryVal,
              ),
            ),
          ),

          // ── 值（自适应宽度，右对齐） ──────────────────────────────────
          Expanded(
            child: Text(
              value,
              style: context.veeText.bodyDefault.copyWith(
                fontWeight: valueWeight,
                color: valueColor ?? VeeTokens.textPrimaryVal,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return row;

    return InkWell(
      onTap: onTap,
      splashColor: VeeTokens.selectedTint(
        Theme.of(context).colorScheme.primary,
      ),
      highlightColor: VeeTokens.hoverTint(
        Theme.of(context).colorScheme.primary,
      ),
      child: row,
    );
  }
}
