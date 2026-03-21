// ─────────────────────────────────────────────────────────────────────────────
// VeeFormRow
//
// 用于：编辑表单内的"图标 + 标签 + 可交互子控件"三列布局。
//
// 与 VeeDetailRow 的区别：
//   - child 是任意 Widget（TextFormField / DropdownButtonFormField / Row...）
//   - 不处理点击事件（由 child 自身处理）
//   - 标签列宽默认 64px（表单标签通常较短）
//
// 用法示例：
//   VeeFormRow(
//     icon: Icons.notes_outlined,
//     label: l10n.note,
//     child: TextFormField(controller: _noteCtrl, ...),
//   )
//   VeeFormRow(
//     icon: Icons.calendar_today_outlined,
//     label: l10n.date,
//     labelWidth: 48,
//     child: Row(children: [Text(...), Icon(Icons.chevron_right)]),
//   )
//
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:vee_app/widgets/ui_core/vee_text_styles.dart';
import 'package:vee_app/widgets/ui_core/vee_tokens.dart';

class VeeFormRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  final double labelWidth;

  const VeeFormRow({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
    this.labelWidth = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: VeeTokens.tilePadding,
      child: Row(
        children: [
          Icon(icon, size: VeeTokens.iconMd, color: VeeTokens.textSecondaryVal),
          const SizedBox(width: VeeTokens.s12),
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: context.veeText.caption.copyWith(
                color: VeeTokens.textSecondaryVal,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
